require "open-uri"
require "net/http"
require "brotli"

class Error < StandardError; end

class HtmlDownloader
  MAX_RETRIES = 3
  RETRY_OPTIONS = {
    tries: MAX_RETRIES,
    base_interval: 1,
    max_interval: 10,
    rand_factor: 0.5,
    on: [
      Error
    ]
  }
  def initialize(url)
    @url = url
  end

  def safe_download
    Retriable.retriable(RETRY_OPTIONS) do
      download
    end
  end

  def download
    # 下载HTML页面
    uri = URI(@url)
    request = Net::HTTP::Get.new(uri)

    # 随机生成 Chrome 版本号 (115-130之间)
    chrome_version = rand(115..130)
    # 随机生成一个合理的时间戳
    timestamp = Time.now.to_i * 1000 + rand(1000)

    request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/#{chrome_version}.0.0.0 Safari/537.36"
    request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    request["Accept-Language"] = "zh-CN,zh;q=0.9,en;q=0.8,ja;q=0.7,zh-TW;q=0.6"
    request["Accept-Encoding"] = "gzip, deflate, br, zstd"
    request["Cache-Control"] = "max-age=0"
    request["Sec-Ch-Ua"] = "\"Chromium\";v=\"#{chrome_version}\", \"Google Chrome\";v=\"#{chrome_version}\", \"Not?A_Brand\";v=\"99\""
    request["Sec-Ch-Ua-Mobile"] = "?0"
    request["Sec-Ch-Ua-Platform"] = "\"Windows\""
    request["Sec-Fetch-Dest"] = "document"
    request["Sec-Fetch-Mode"] = "navigate"
    request["Sec-Fetch-Site"] = "none"
    request["Sec-Fetch-User"] = "?1"
    request["Upgrade-Insecure-Requests"] = "1"
    request["Priority"] = "u=0, i"
    request["X-Requested-With"] = "XMLHttpRequest"
    request["X-Request-Time"] = timestamp.to_s

    # 如果有上一个页面的URL，添加 Referer
    if @referer
      request["Referer"] = @referer
    end

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    # 根据响应的 Content-Encoding 处理内容
    case response["Content-Encoding"]
    when "br"
      Brotli.inflate(response.body)
    when "gzip"
      Zlib::GzipReader.new(StringIO.new(response.body)).read
    when "deflate"
      Zlib::Inflate.inflate(response.body)
    else
      response.body
    end
    # 使用Nokogiri解析解压后的HTML
  rescue OpenURI::HTTPError => e
    puts "下载页面时发生错误: #{e.message}"
  rescue => e
    puts "发生错误: #{e.message}"
    raise Error, e.message
  end
end

SmartPrompt.define_worker :download_page do
  downloader = HtmlDownloader.new(params[:url])
  downloader.safe_download
end
