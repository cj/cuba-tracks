module FormBuilder
  class RadioInput < Input
    def display
      options[:type] = :radio

      radios = options[:radios] || [:yes, :no]

      opts = options.dup

      mab do
        div class: 'form-control' do
          radios.each_with_index do |name, i|
            name = name.to_s
            opts[:value] = name
            opts[:id]    =  "#{options[:id]}_#{i}"
            opts[:class].gsub!(/form-control/, '')

            if (opts[:value] == 'no' and data.value == false) \
            or (opts[:value] == 'yes' and data.value == true)
              opts[:checked] = 'checked'
            else
              opts.delete :checked
            end

            input opts
            span name.humanize
          end
        end
      end
    end
  end
end
