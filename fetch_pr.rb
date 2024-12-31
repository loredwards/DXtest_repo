require 'net/http'
require 'json'
require 'csv'
require 'uri'
require 'time'

username = 'loredwards'
repo = 'DXtest_repo'
token = ENV['GITHUB_TOKEN']
uri = URI("https://api.github.com/repos/#{username}/#{repo}/pulls?state=all")

request = Net::HTTP::Get.new(uri)
request['Authorization'] = "token #{token}"
request['User-Agent'] = 'Ruby'

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

pull_requests = JSON.parse(response.body)

if pull_requests.is_a?(Hash) && pull_requests['message']
  puts "Error from GitHub API: #{pull_requests['message']}"
  exit
end

if !pull_requests.is_a?(Array)
  puts "Unexpected response format: #{pull_requests.class}"
  exit
end

CSV.open('pull_requests.csv', 'w') do |csv|
  csv << ['PR Number', 'Author', 'Author ID', 'Merged By', 'Merged By ID', 'Additions', 'Deletions', 'Created At', 'Merged At', 'Time to Merge (hours)']
  pull_requests.each do |pr|
    pr_number = pr['number']
    author = pr['user']['login']
    author_id = pr['user']['id']
    merged_by = pr['merged_by'] ? pr['merged_by']['login'] : 'Not Merged'
    merged_by_id = pr['merged_by'] ? pr['merged_by']['id'] : 'N/A'
    additions = pr['additions'] || 0
    deletions = pr['deletions'] || 0
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