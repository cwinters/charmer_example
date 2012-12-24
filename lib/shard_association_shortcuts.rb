# little help on defining your own AR class methods: http://www.mail-archive.com/rubyonrails-talk@googlegroups.com/msg28549.html
module ShardAssociationShortcuts
  module ActiveRecord

    def self.included(base)
      puts "ShardAssociationShortcuts: included into #{base.to_s}"
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      # The 'current_shard' called by the first two is the method on the class, so we need
      # to give it a hint with our current connection
      def belongs_to_in_shard(name, options = {})
        rv = belongs_to(name, options)
        id_name = options[:id] || "#{name.to_s}_id".to_sym
        relation_class = name.to_s.camelize.constantize
        self.send(:define_method, name) { relation_class.current_shard(self.connection.real_conn).find(self.send(id_name)) }
        puts "DEFINE belongs_to_in_shard [Class: #{self.to_s}] [Name: #{name}] [ID name: #{id_name}] [Relation class: #{relation_class.to_s}]"
        rv
      end

      def has_one_in_shard(name, options = {})
        rv = has_one(name, options)
        id_name = options[:id] || "#{self.class.to_s.downcase}_id".to_sym
        relation_class = name.to_s.camelize.constantize
        self.send(:define_method, name) { relation_class.current_shard(self.connection.real_conn).where(id_name, self.id) }
        puts "DEFINE has_one_in_shard [Class: #{self.to_s}] [Name: #{name}] [ID name: #{id_name}] [Relation class: #{relation_class.to_s}]"
        rv
      end

      # The 'current_shard' called on this one is defined on the collection proxy, which
      # will use the association owner's current connection
      def has_many_in_shard(name, options = {})
        rv = has_many(name, options)
        self.send(:define_method, name) { super().current_shard }
        puts "DEFINE has_many_in_shard [Class: #{self.to_s}] [Name: #{name}]"
        rv
      end

    end
  end
end