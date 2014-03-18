module Cuba::Sugar
  module As
    # leave res.write upto the user
    # https://github.com/cj/cuba-sugar/blob/eb70271b4dab3cdb16480b7f178b7053adc08907/lib/cuba/sugar/as.rb
    def as(http_code = 200, extra_headers = {}, &block)
      res.status = http_code
      res.headers.merge! extra_headers
      yield if block
    end
  end
end
