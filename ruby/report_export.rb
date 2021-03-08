require 'http'

class HolisticsAPI

  def initialize(api_key, host: 'secure.holistics.io')
    @api_key = api_key
    @api_url = "https://#{host}/api/v2"
    @http = HTTP.headers({'X-Holistics-Key' => @api_key})
  end


  def submit_report(widget_id, output: 'csv')
    url = @api_url + "/dashboard_widgets/" + widget_id.to_s + "/submit_export"

    response = @http.post(url, json: {output: output})
    res = JSON.parse(response.to_s)

    if response.code == 200
      res['job']['id']
    else
      raise StandardError.new(res['message'])
    end
  end

  def wait_for_job_status(job_id)
    url = @api_url + "/jobs/" + job_id.to_s

    while true do
      response = @http.get(url)
      res = JSON.parse(response.to_s)

      raise StandardError.new(res['message']) if response.code != 200

      status = res['job']['status']
      puts "===> status: #{status}"

      unless ['created', 'running', 'queued'].include?(status)
        return status
      end

      # Wait a while before pinging again
      sleep 2
    end
  end

  def download_export(job_id)
    url = @api_url + "/exports/download"
    response = @http.follow.get(url, params: {job_id: job_id})

    raise StandardError.new(JSON.parse(response.to_s['message'])) if response.code != 200

    response.to_s
  end

end

API_KEY = 'your api key'
api = HolisticsAPI.new(API_KEY)

job_id = api.submit_report(3264)
puts "===> job_id: #{job_id}"

job_status = api.wait_for_job_status(job_id)
puts "===> job_status: #{job_status}"

if job_status == 'success'
  csv_data = api.download_export(job_id)
  puts csv_data
end

