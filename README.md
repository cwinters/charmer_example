# DB Charmer Example

This is a very simple example of DB Charmer to test sharding and
notes recorded during its setup.

## Setup

Create basic models:

    $ rails new charmer_example
    $ cd charmer_example/
    $ rails generate scaffold user login name school_id:integer
    $ rails generate scaffold school name
    $ rails generate scaffold classroom name school_id:integer
    $ rails generate scaffold enrollment user_id:integer classroom_id:integer
    $ rails generate scaffold enrollment lesson enrollment_id:integer name
    $ rails generate scaffold lesson enrollment_id:integer name
    $ rails generate scaffold attempt user_id:integer lesson_id:integer correct:boolean response

Create databases to mirror `config/database.yml`:

    $ createdb charmer_development
    $ createdb shard_charmer_one
    $ createdb shard_charmer_two
    $ createdb shard_charmer_three
    $ createdb shard_charmer_four

## Migrations

DB charmer sticks a `db_magic` method that we can use to assign
connections. Documentation has the definition of those shards as
static symbols, but we can define them elsewhere and re-use:

    config/enviornmnets/development.rb:
    
      CharmerExample::Application.configure do
        config.shards = [ :shard_one, :shard_two, :shard_three, :shard_four ]
        ...

The symbols like `:shard_one` match the names in
our database configuration, which looks like this:

    config/database.yml:
      development:
        # default connection, 'master'
        adapter: postgresql
        encoding: utf8
        database: charmer_development
        min_messages: WARNING
        host: 127.0.0.1
      
        shard_one:
          adapter: postgresql
          encoding: utf8
          database: shard_charmer_one
          min_messages: WARNING
          host: 127.0.0.1
        shard_two:
          ...

In each migration that has sharded tables we assign the
`db_magic :connections` to our set of shard names:

    db/migrate/20121129165209_create_attempts.rb:
      class CreateAttempts < ActiveRecord::Migration
        db_magic :connections => CharmerExample::Application.config.shards
        def change
          create_table :attempts do |t|
            t.integer :user_id
            t.integer :lesson_id
            t.boolean :correct
            t.text :response
            t.timestamps
          end
        end
      end

The output looks like this -- DB Charmer helpfully tells you
against which shards it's running the migration:

    cwinters@abita:~/Projects/charmer_example$ rake db:migrate
    # example migrating non-sharded table...
    ==  CreateUsers: migrating ====================================================
    -- create_table(:users)
       -> 0.1232s
    ==  CreateUsers: migrated (0.1235s) ===========================================

    ...
    
    # example migrating sharded table...
    ==  CreateAttempts: Switching connection to :shard_one ========================
    ==  CreateAttempts: migrating =================================================
    -- create_table(:attempts)
       -> 0.1200s
    ==  CreateAttempts: migrated (0.1204s) ========================================
    
    ==  CreateAttempts: Switching connection back =================================
    ==  CreateAttempts: Switching connection to :shard_two ========================
    ==  CreateAttempts: migrating =================================================
    -- create_table(:attempts)
       -> 0.1193s
    ==  CreateAttempts: migrated (0.1195s) ========================================
    
    ==  CreateAttempts: Switching connection back =================================
    ==  CreateAttempts: Switching connection to :shard_three ======================
    ==  CreateAttempts: migrating =================================================
    -- create_table(:attempts)
       -> 0.1029s
    ==  CreateAttempts: migrated (0.1032s) ========================================
    
    ==  CreateAttempts: Switching connection back =================================
    ==  CreateAttempts: Switching connection to :shard_four =======================
    ==  CreateAttempts: migrating =================================================
    -- create_table(:attempts)
       -> 0.1194s
    ==  CreateAttempts: migrated (0.1197s) ========================================
    
    ==  CreateAttempts: Switching connection back =================================

And if we look with Postgres we see the list of databases we
created earlier as well as the tables in a couple of shards:

    cwinters@abita:~/Projects/charmer_example$ psql 
    Timing is on.
    psql (9.1.6)
    Type "help" for help.
    
    cwinters=# \l
                                           List of databases
            Name         |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
    ---------------------+----------+----------+-------------+-------------+-----------------------
     charmer_development | cwinters | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
     ...
     postgres            | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
     shard_charmer_four  | cwinters | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
     shard_charmer_one   | cwinters | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
     shard_charmer_three | cwinters | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
     shard_charmer_two   | cwinters | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
     template0           | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
                         |          |          |             |             | postgres=CTc/postgres
     template1           | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
                         |          |          |             |             | postgres=CTc/postgres
    (16 rows)
    
    cwinters=# \c shard_charmer_one 
    You are now connected to database "shard_charmer_one" as user "cwinters".
    shard_charmer_one=# \d
                     List of relations
     Schema |        Name        |   Type   |  Owner   
    --------+--------------------+----------+----------
     public | attempts           | table    | cwinters
     public | attempts_id_seq    | sequence | cwinters
     public | enrollments        | table    | cwinters
     public | enrollments_id_seq | sequence | cwinters
     public | lessons            | table    | cwinters
     public | lessons_id_seq     | sequence | cwinters
    (6 rows)
    
    cwinters=# \c shard_charmer_two 
    You are now connected to database "shard_charmer_two" as user "cwinters".
    shard_charmer_two=# \d
                     List of relations
     Schema |        Name        |   Type   |  Owner   
    --------+--------------------+----------+----------
     public | attempts           | table    | cwinters
     public | attempts_id_seq    | sequence | cwinters
     public | enrollments        | table    | cwinters
     public | enrollments_id_seq | sequence | cwinters
     public | lessons            | table    | cwinters
     public | lessons_id_seq     | sequence | cwinters
    (6 rows)

## Changes to normal activities

### @record.save!

The standard Rails way to create new objects is:

    @enrollment = Enrollment.new( params[:enrollment] )
    respond_to do |format|
      if @enrollment.save
        ...
    end

But this doesn't wire in the call to find the shard. Instead you
need something like the following, since 'shard_for' is a class
method:

    respond_to do |format|
      @enrollment = Enrollment.shard_for( params[:classroom_id] ).create!( params[:enrollment] )
      if @enrollment
        ...

## Sharding Concerns

What do we need to be concerned with when sharding?

1. Is the per-shard data ("chunk") self contained? If at all
   possible we don't want to do cross-database joins, or simulate
   them in the app. This impacts the granularity at which we
   distribute sharded data. With the Enrollments data the
   granularity is the school, since reports that we run do so
   over a school.  
2. How do we decide where a chunk goes? This can be random (round
   robin, modulo the ID by shard count, whatever). But it can
   also draw from application knowledge: for example, we may want
   to distribute a district's schools as evenly as possible
   across the shards.
3. How do we ensure ID uniqueness across the shards? Currently we
   use the default ActiveRecord strategy for PostgreSQL -- a
   SEQUENCE defined as a default on the table being inserted
   into. But instead we should generate the IDs from a sequence
   at the master table.
   

