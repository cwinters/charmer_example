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

## DB Charmer notes

### Associations

We'd like associations for objects on the same shard to Just
Work. If I have a LessonEnrollment in 'enrollments' schema on
shard 1, when I call:

    lesson_enrollment.enrollment
    
I shouldn't have to tell the model that it needs to find the
related enrollment (which is also in the 'enrollments' schema) on
the same shard. How can we make that happen?

- Model has 'db_magic' call in `DbCharmer::ActiveRecord::DbMagic`
  (not sure how this gets made available to models...)
- specifying `:sharded` option adds the class
  `DbCharmer::ActiveRecord::Sharding` to the model (via
  `self.extend`); this adds the methods `shard_for`,
  `on_default_shard`, `on_each_shard` to the model.
- `shard_for` allows you to specify a key that's used to lookup
  the shard, so you can do:
  
      Enrollment.shard_for(10).find(10)

The '10' in this case is used to lookup the shard, it's not the
shard name itself. To do that you use `on_db`, like this dumb
method I wrote to lookup an enrollment across all shards. It
grabs the shard names from configuration and passes each to
`on_db` to get a connection to that database.

    def self.multi_find(id)
      enum       = CharmerExample::Application.config.shards.to_enum
      enrollment = nil
      loop do
        begin
          enrollment = Enrollment.on_db(enum.next).find(id)
          break if enrollment
        rescue
          # ignored
        end
      end
      return enrollment
    end

- Associations seem to reference a module's overridden
  `build_scope` in
  DbCharmer::ActiveRecord::Preloader::Association. It's a short
  method but I'm including some other metadata because it's
  important::
  
      ...
      module Association
        extend ActiveSupport::Concern
        included do
          alias_method_chain :build_scope, :db_magic
        end
  
        def build_scope_with_db_magic
          if model.db_charmer_top_level_connection? || reflection.options[:polymorphic] ||
              model.db_charmer_default_connection != klass.db_charmer_default_connection
            build_scope_without_db_magic
          else
            build_scope_without_db_magic.on_db(model)
          end
        end

The `build_scope_without_db_magic` confounded me for a
while. There was no code to be found for it. And as a general
rule, if there's no code to be found that means Rails generates
it for you. This is no exception. The name of this method is
`build_scope_with_db_magic` so the name of the ORIGINAL method is
`build_scope_without_db_magic`. The method is basically trying to
figure out if it should re-use the original model's connection.

(See for more this [Stack Overflow question](http://stackoverflow.com/questions/3695839/ruby-on-rails-alias-method-chain-what-exactly-does-it-do))


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
   at the master table. We can create a common `before_create`
   callback for such tables.
4. Will uniqueness constraints need to be enforced at the
   application level instead of the database level? This is
   somewhat related to item 1 -- depending on how the per-shard
   data is broken up
   

