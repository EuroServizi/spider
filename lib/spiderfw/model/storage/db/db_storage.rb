require 'spiderfw/model/storage/base_storage'

module Spider; module Model; module Storage; module Db
    
    class DbStorage < Spider::Model::Storage::BaseStorage
        @reserved_keywords = ['from', 'order', 'where']
        @safe_conversions = {
            'TEXT' => ['LONGTEXT'],
            'INT' => ['TEXT', 'LONGTEXT', 'REAL'],
            'REAL' => ['TEXT']
        }
        @capabilities = {
            :autoincrement => false,
            :sequences => true,
            :transactions => true
        }

        class << self
            attr_reader :reserved_keywords, :safe_conversions, :capabilities
        end
        
        def initialize(url)
            super
        end
        
        def get_mapper(model)
            require 'spiderfw/model/mappers/db_mapper'
            mapper = Spider::Model::Mappers::DbMapper.new(model, self)
            return mapper
        end
        
        def supports?(capability)
            self.class.capabilities[capability]
        end
        
        def supports_transactions?
            return false
        end
        
        def start_transaction
           raise StorageException, "The current storage does not support transactions" 
        end
        
        def in_transaction?
            return false
        end
        
        def commit
        end
        
        def rollback
            raise StorageException, "The current storage does not support transactions" 
        end
        
        def lock(table, mode=:exclusive)
            lockmode = case(mode)
            when :shared
                'SHARE'
            when :row_exclusive
                'ROW EXCLUSIVE'
            else
                'EXCLUSIVE'
            end
            execute("LOCK TABLE #{table} IN #{lockmode} MODE")
        end
        
        def assigned_key(name)
        end
        
        ##############################################################
        #   Methods used to generate a schema                        #
        ##############################################################
        
        # Fixes a string to be used as a table name
        def table_name(name)
            return name.to_s.gsub(':', '_')
        end
        
        # Fixes a string to be used as a column name
        def column_name(name)
            name = name.to_s
            name += '_field' if (self.class.reserved_keywords.include?(name.downcase)) 
            return name
        end
        
        # Returns the db type corresponding to an element type
        def column_type(type, attributes)
            case type
            when 'text'
                'TEXT'
            when 'longText'
                'LONGTEXT'
            when 'int'
                'INT'
            when 'real'
                'REAL'
            when 'dateTime'
                'DATE'
            when 'binary'
                'BLOB'
            when 'bool'
                'INT'
            end
        end
        
        # Returns the attributes corresponding to element type and attributes
        def column_attributes(type, attributes)
            db_attributes = {}
            case type
            when 'text', 'longText'
                db_attributes[:length] = attributes[:length] if (attributes[:length])
            when 'real'
                db_attributes[:length] = attributes[:length] if (attributes[:length])
                db_attributes[:precision] = attributes[:precision] if (attributes[:precision])
            when 'binary'
                db_attributes[:length] = attributes[:length] if (attributes[:length])
            when 'bool'
                db_attributes[:length] = 1
            end
            db_attributes[:autoincrement] = attributes[:autoincrement]
            return db_attributes
        end
        
        ##################################################################
        #   Preparing values                                             #
        ##################################################################
        
        def value_for_save(type, value, save_mode)
            return prepare_value(type, value)
        end
        
        def value_for_condition(type, value)
            return prepare_value(type, value)
        end
        
        def value_to_mapper(type, value)
            return prepare_value(type, value)
        end
        
        def prepare_value(type, value)
            return value
        end
        
        def query(query)
            @last_query = query
            case query[:query_type]
            when :select
                sql, bind_vars = sql_select(query)
                execute(sql, *bind_vars)
            when :count
                query[:keys] = 'COUNT(*) AS N'
                sql, bind_vars = sql_select(query)
                return execute(sql, *bind_vars)[0]['N']
            end
        end
        
        def sql_select(query)
            bind_vars = query[:bind_vars] || []
            tables_sql, tables_values = sql_tables(query)
            sql = "SELECT #{sql_keys(query)} FROM #{tables_sql} "
            bind_vars += tables_values
            where, vals = sql_condition(query)
            bind_vars += vals
            sql += "WHERE #{where} " if where && !where.empty?
            order = sql_order(query)
            sql += "ORDER BY #{order} " if order && !order.empty?
            limit = sql_limit(query)
            sql += limit if limit
            return sql, bind_vars
        end
        
        def sql_keys(query)
            query[:keys].join(',')
        end
        
        def sql_tables(query)
            values = []
            sql = query[:tables].map{ |table|
                str = table
                if (query[:joins] && query[:joins][table])
                    
                    query[:joins][table].each_key do |to_table|
                        join, join_values = sql_joins(query[:joins][table][to_table])
                        str += " "+join
                        values += join_values
                    end
                end
                str
            }.join(', ')
            return [sql, values]
        end
        
        
        def sql_condition(query)
            condition = query[:condition]
            return ['', []] unless (condition && condition[:values])
            bind_vars = []
            mapped = condition[:values].map do |v|
                if (v.is_a? Hash) # subconditions
                    sql, vals = sql_condition({:condition => v})
                    bind_vars += vals
                    !sql.empty? ? "(#{sql})" : nil
                else
                    v[2].upcase! if (v[1].to_s.downcase == 'ilike')
                    bind_vars << v[2]
                    sql_condition_value(v[0], v[1], v[2])
                end
            end
            return mapped.select{ |p| p != nil}.join(' '+condition[:conj]+' '), bind_vars
        end
        
        def sql_condition_value(key, comp, value)
            if (comp.to_s.downcase == 'ilike')
                comp = 'like'
                key = "UPPER(#{key})"
            end
            "#{key} #{comp} ?"
        end
        
        # def sql_join(joins)
        #     sql = ""
        #     joins.each_key do |from_table|
        #         joins[from_table].each do |to_table, conditions|
        #             conditions.each do |from_key, to_key|
        #                 sql += " AND " unless sql.empty?
        #                 sql += "#{from_table}.#{from_key} = #{to_table}.#{to_key}"
        #             end
        #         end
        #     end
        #     return sql
        # end
        
        def sql_joins(joins)
            types = {
                :inner => 'INNER', :outer => 'OUTER', :left_outer => 'LEFT OUTER', :right_outer => 'RIGHT OUTER'
            }
            values = []
            sql = joins.map{ |join|
                sql_on = join[:keys].map{ |from_f, to_f| "#{join[:from]}.#{from_f} = #{join[:to]}.#{to_f}"}.join(' AND ')
                if (join[:condition])
                    condition_sql, condition_values = sql_condition({:condition => join[:condition]})
                    sql_on += " and #{condition_sql}"
                    values += condition_values
                end
                "#{types[join[:type]]} JOIN #{join[:to]} ON (#{sql_on})"
            }.join(" ")
            return [sql, values]
        end
        
        def sql_order(query)
            return '' unless query[:order]
            return query[:order].map{|o| "#{o[0]} #{o[1]}"}.join(' ,')
        end
        
        def sql_limit(query)
            sql = ""
            sql += "LIMIT #{query[:limit]} " if query[:limit]
            sql += "OFFSET #{query[:offset]} " if query[:offset]
        end
        
        def sql_insert(insert)
            sql = "INSERT INTO #{insert[:table]} (#{insert[:values].keys.join(', ')}) " +
                  "VALUES (#{insert[:values].values.map{'?'}.join(', ')})"
            return [sql, insert[:values].values]
        end
        
            
        def sql_update(update)
            values = update[:values].values
            sql = "UPDATE #{update[:table]} SET "
            sql += sql_update_values(update)
            where, bind_vars = sql_condition(update)
            values += bind_vars
            sql += " WHERE #{where}"
            return [sql, values]
        end
        
        def sql_update_values(update)
            update[:values].map{ |k, v| 
                "#{k} = ?"
            }.join(', ')
        end
        
        def sql_delete(delete)
            where, bind_vars = sql_condition(delete)
            sql = "DELETE FROM #{delete[:table]} WHERE #{where}"
            return [sql, bind_vars]
        end
        
        def sql_create_table(create)
            name = create[:table]
            fields = create[:fields]
            sql_fields = ''
            fields.each do |field|
                attributes = field[:attributes]
                attributes ||= {}
                length = attributes[:length]
                sql_fields += ', ' unless sql_fields.empty?
                sql_fields += sql_table_field(field[:name], field[:type], field[:attributes])
            end
            ["CREATE TABLE #{name} (#{sql_fields})"]
        end
        
        def sql_alter_table(alter)
            current = alter[:current]
            table_name = alter[:table]
            add_fields = alter[:add_fields]
            alter_fields = alter[:alter_fields]
            sqls = []
            
            add_fields.each do |field|
                name, type, attributes = field
                sqls += sql_add_field(table_name, field[:name], field[:type], field[:attributes])
            end
            alter_fields.each do |field|
                name, type, attributes = field
                sqls += sql_alter_field(table_name, field[:name], field[:type], field[:attributes])
            end
            return sqls
            # if (@config[:drop_fields])
            #     current.each_key do |field|
            #         if (!fields[field])
            #             sql = "ALTER TABLE #{name} DROP #{field}"
            #             @storage.execute(sql)
            #         end
            #     end
            # end
        end
        
        def create_table(create)
            sqls = sql_create_table(create)
            sqls.each do |sql|
                execute(sql)
            end
        end
        
        def alter_table(alter)
            sqls = sql_alter_table(alter)
            sqls.each do |sql|
                execute(sql)
            end
        end
        
        def sql_table_field(name, type, attributes)
            f = "#{name} #{type}"
            if attributes[:length] && attributes[:length] != 0
                f += "(#{attributes[:length]})"
            elsif attributes[:precision]
                f += "(#{attributes[:precision]}"
                f += "#{attributes[:scale]}" if attributes[:scale]
                f += ")"
            end
            return f
        end
        
        def sql_add_field(table_name, name, type, attributes)
            ["ALTER TABLE #{table_name} ADD #{sql_table_field(name, type, attributes)}"]
        end
        
        def sql_alter_field(table_name, name, type, attributes)
            ["ALTER TABLE #{table_name} ALTER #{sql_table_field(name, type, attributes)}"]
        end
        
        def schema_field_equal?(current, field)
            attributes = field[:attributes]
           return true if current[:type] == field[:type] && current[:length] == attributes[:length] && current[:precision] == attributes[:precision]
           return true if (current[:length] == 0 && !field[:length]) || (!current[:length] && field[:length] == 0)
           return true if (current[:precision] == 0 && !field[:precision]) || (!current[:precision] && field[:precision] == 0)     
           return false
        end
        
        def safe_schema_conversion?(current, field)
            attributes = field[:attributes]
            safe = self.class.safe_conversions
            if (current[:type] != field[:type])
                if safe[current[:type]] && safe[current[:type]].include?(field[:type])
                    return true 
                else
                    return false
                end
            end
            return true if ((!current[:length] || current[:length] == 0) \
                            || (attributes[:length] && current[:length] <= attributes[:length])) && \
                           ((!current[:precision] || current[:precision] == 0) \
                           || (attributes[:precision] && current[:precision] <= attributes[:precision]))
            return false
        end
            
            
        
    end
    
end; end; end; end