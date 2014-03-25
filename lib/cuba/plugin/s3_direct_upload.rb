require "singleton"

module S3DirectUpload
  class Config
    include Singleton

    attr_accessor :access_key_id, :secret_access_key, :bucket, :prefix_to_clean, :region, :url
  end

  def self.config
    if block_given?
      yield Config.instance
    end
    Config.instance
  end

  module UploadHelper
    def self.setup app
      S3DirectUpload.config do |c|
        c.access_key_id = ENV['AWS_ACCESS_KEY_ID'] # your access key id
        c.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] # your secret access key
        c.bucket = "mdocs_#{app.environment}" # your bucket name
        c.region = nil # region prefix of your bucket url. This is _required_ for the non-default AWS region, eg. "s3-eu-west-1"
        c.url = nil # S3 API endpoint (optional), eg. "https://#{c.bucket}.s3.amazonaws.com/"
      end
    end

    def s3_uploader options = {}, &block
      uploader = S3Uploader.new(options)


      opts = {
        action: uploader.url,
      }.merge uploader.form_options

      opts[:class] += ' s3_upload_form'

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
            text! block.call(self)
          end
        end
      end
    end

    class S3Uploader
      def initialize(options)
        @key_starts_with = options[:s3_upload_path].call(options.delete(:record)) || options[:key_starts_with] || "uploads/"
        @options = options.reverse_merge(
          aws_access_key_id: S3DirectUpload.config.access_key_id,
          aws_secret_access_key: S3DirectUpload.config.secret_access_key,
          bucket: options[:bucket] || S3DirectUpload.config.bucket,
          region: S3DirectUpload.config.region || "s3",
          url: S3DirectUpload.config.url,
          ssl: true,
          acl: "public-read",
          expiration: 10.hours.from_now.utc.iso8601,
          max_file_size: 500.megabytes,
          callback_method: "POST",
          callback_param: "file",
          key_starts_with: @key_starts_with,
          key: key
        )
      end

      def form_options
        {
          id: @options[:id],
          class: @options[:class] || '',
          method: "post",
          authenticity_token: false,
          enctype: "multipart/form-data",
          data: {
            'callback-url' => @options[:callback_url],
            'callback-method' => @options[:callback_method],
            'callback-param' => @options[:callback_param],
            'callback-data' => @options[:data].to_json
          }
        }
      end

      def fields
        {
          :key => @options[:key] || key,
          :acl => @options[:acl],
          "AWSAccessKeyId" => @options[:aws_access_key_id],
          :policy => policy,
          :signature => signature,
          :success_action_status => "201",
          'X-Requested-With' => 'xhr'
        }
      end

      def key
        @key ||= "#{@key_starts_with}{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}"
      end

      def url
        @options[:url] || "http#{@options[:ssl] ? 's' : ''}://#{@options[:region]}.amazonaws.com/#{@options[:bucket]}/"
      end

      def policy
        Base64.encode64(policy_data.to_json).gsub("\n", "")
      end

      def policy_data
        {
          expiration: @options[:expiration],
          conditions: [
            ["starts-with", "$key", @options[:key_starts_with]],
            ["starts-with", "$x-requested-with", ""],
            ["content-length-range", 0, @options[:max_file_size]],
            ["starts-with","$content-type", @options[:content_type_starts_with] ||""],
            {bucket: @options[:bucket]},
            {acl: @options[:acl]},
            {success_action_status: "201"}
          ] + (@options[:conditions] || [])
        }
      end

      def signature
        Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest.new('sha1'),
            @options[:aws_secret_access_key], policy
          )
        ).gsub("\n", "")
      end
    end
  end
end
