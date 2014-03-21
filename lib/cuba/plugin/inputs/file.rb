module FormBuilder
  class FileInput < Input
    def display
      opts = {
        class: '',
        record: record
      }.reverse_merge options

      opts[:class] += ' s3_upload_form'

      uploader =  S3DirectUpload::UploadHelper::S3Uploader.new(opts)

      opts = {
        action: uploader.url
      }.merge uploader.form_options

      data = opts.delete(:data)

      data.each do |key, value|
        opts["data-#{key}"] = value
      end

      mab do
        html do
          div opts do
            uploader.fields.map do |name, value|
              input type: :hidden, name: name, value: value
            end

            input type: (options[:value] ? :hidden : :file), name: options[:name], class: 'form-control file', value: options[:value]
          end
        end
      end
    end
  end
end
