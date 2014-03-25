module FormBuilder
  class FileInput < Input
    def display
      key = options[:s3_upload_path].call(record)

      mab do
        if options[:value]
          input id: id, type: :hidden, name: options[:name], class: 'form-control file', value: options[:value], 'data-s3-uploader' => S3Uploader.js_button_options(id, key, options[:success_url], options[:params])
        else
          div id: id, name: options[:name], class: 'form-control file', value: options[:value], 'data-s3-uploader' => S3Uploader.js_button_options(id, key, options[:success_url], options[:params])
          text! S3Uploader.js_button(id, key, options[:success_url], options[:params])
        end
      end
    end
  end
end
