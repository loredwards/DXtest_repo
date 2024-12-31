require 'net/http'
require 'json'
require 'csv'
require 'uri'
require 'time'

username = 'loredwards'
repo = 'DXtest_repo'
token = ENV['GITHUB_TOKEN']
base_url = "https://api.github.com/repos/#{username}/#{repo}"

uri = URI("#{base_url}/pulls?state=all")
request = Net::HTTP::Get.new(uri)
request['Authorization'] = "token #{token}"
request['User-Agent'] = 'Ruby'
request['Accept'] = 'application/vnd.github+json'

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

pull_requests = JSON.parse(response.body)

CSV.open('pull_requests.csv', 'w') do |csv|
  csv << ['PR Number', 'Author', 'Author ID', 'Merged By', 'Merged By ID', 'Additions', 'Deletions', 'Created At', 'Merged At', 'Time to Merge (hours)']

  pull_requests.each do |pr|
    pr_number = pr['number']
    author = pr['user']['login']
    author_id = pr['user']['id']
    merged_by = pr['merged_by'] ? pr['merged_by']['login'] : 'Not Merged'
    merged_by_id = pr['merged_by'] ? pr['merged_by']['id'] : 'N/A'

    pr_details_uri = URI("#{base_url}/pulls/#{pr_number}")
    pr_details_request = Net::HTTP::Get.new(pr_details_uri)
    pr_details_request['Authorization'] = "token #{token}"
    pr_details_request['User-Agent'] = 'Ruby'
    pr_details_request['Accept'] = 'application/vnd.github+json'

    pr_details_response = Net::HTTP.start(pr_details_uri.hostname, pr_details_uri.port, use_ssl: true) do |http|
      http.request(pr_details_request)
    end
    pr_details = JSON.parse(pr_details_response.body)

    additions = pr_details['additions'] || 0
    deletions = pr_details['deletions'] || 0
    created_at = pr['created_at']
    merged_at = pr['merged_at']

    time_to_merge = if created_at && merged_at
                      ((Time.parse(merged_at) - Time.parse(created_at)) / 3600).round(2)
                    else
                      'Not Merged'
                    end

    csv << [pr_number, author, author_id, merged_by, merged_by_id, additions, deletions, created_at, merged_at, time_to_merge]
  end
end

puts "Pull requests saved to pull_requests.csv"