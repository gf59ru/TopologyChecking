{
    :ru =>
        {:i18n =>
             {:plural =>
                  {:keys => [:one, :few, :other],
                   :rule => lambda { |n|
                     n %= 100
                     case n
                       when 5..20
                         :other
                       else
                         n %= 10
                         case n
                           when 1
                             :one
                           when 2..4
                             :few
                           else
                             :other
                         end
                     end
                   }
                  }
             }
        }
}