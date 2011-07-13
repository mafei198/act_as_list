module ActiveRecord
  module Acts
    module List
      def self.included(base)
        base.extend         ClassMethods
      end # self.included

      module ClassMethods
        def act_as_items(options = {})
          raise "Exceptions from act_as_list, you must figure out which model to mount.\n i.e \n act_as_list :mount => :xxx" if options[:mount] == nil

          class_eval do
            after_create  :add__to_list
            after_destroy :remove_from_list

            define_method :move_higher do
              if in_list? and !top? 
                current = list_array.index(id)
                exchange current, current - 1
              end
            end

            define_method :move_lower do
              if in_list? and !bottom?
                current = list_array.index(id)
                exchange current, current + 1
              end
            end

            define_method :move_to_top do
              if in_list? and !top? 
                current = list_array.index(id)
                exchange current, 0
              end
            end

            define_method :move_to_bottom do
              if in_list? and !bottom?
                current = list_array.index(id)
                exchange current, list_array.length - 1
              end
            end

            define_method :move_to do |location_number|
              return false unless location_number >= 1 and location_number <= list_array.length 

              case location_number
              when 1
                move_to_top
              when list_array.length
                move_to_bottom
              else
                current = list_array.index(id)
                exchange current, location_number - 1
              end
            end

            define_method :exchange do |current_id,swap_id|
              arr = list_array
              arr[current_id], arr[swap_id] = arr[swap_id], arr[current_id]
              update_list_with arr.join(',')
            end

            define_method :list_array do
              send(options[:mount]).list_array
            end

            define_method :in_list? do
              !!list_array.index(id)
            end

            define_method :top? do
              list_array.first == id
            end

            define_method :bottom? do
              list_array.last == id
            end

            private
            define_method :add__to_list do
              new_list = send(options[:mount]).order_list.to_s + ",#{id.to_s}"
              update_list_with new_list
            end

            define_method :remove_from_list do
              new_list = (send(options[:mount]).order_list.split(',') - id.to_s.to_a).join(',')
              update_list_with new_list
            end

            define_method :update_list_with do |new_list|        
              send(options[:mount]).update_attribute(:order_list, new_list)
            end
          end
        end

        def act_as_list(options = {})
          class_eval do
            define_method :list do
              return [] if list_empty?
              list_array.collect do |item_id|
                send(options[:items]).each do |item|
                  break item if item.id == item_id
                end
              end
            end

            def list_empty?
              order_list == nil or order_list == ',' or order_list == ''
            end

            def list_array
              str_array = order_list.split(',').delete_if{|e| e == '' }
              str_array.map{|item_id|item_id.to_i}
            end
          end
        end

      end # ClassMethods

    end
  end
end
