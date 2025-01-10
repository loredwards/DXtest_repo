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

CSV.open('pull_requests.csv', 'w') do |csv|
  csv << ['PR Number', 'Author', 'Author ID', 'Merged By', 'Merged By ID', 'Additions', 'Deletions', 'Created At', 'Merged At', 'Time to Merge (hours)']

  pull_requests.each do |pr|
    pr_number = pr['number']
    
    pr_uri = URI("https://api.github.com/repos/#{username}/#{repo}/pulls/#{pr_number}")
    pr_request = Net::HTTP::Get.new(pr_uri)
    pr_request['Authorization'] = "token #{token}"
    pr_request['User-Agent'] = 'Ruby'
    pr_response = Net::HTTP.start(pr_uri.hostname, pr_uri.port, use_ssl: true) { |http| http.request(pr_request) }
    pr_details = JSON.parse(pr_response.body)

    author = pr_details['user']['login']
    author_id = pr_details['user']['id']
    merged_by = pr_details['merged_by'] ? pr_details['merged_by']['login'] : 'Not Merged'
    merged_by_id = pr_details['merged_by'] ? pr_details['merged_by']['id'] : 'N/A'
    additions = pr_details['additions']
    deletions = pr_details['deletions']
    created_at = pr_details['created_at']
    merged_at = pr_details['merged_at']
    time_to_merge = if created_at && merged_at
                      ((Time.parse(merged_at) - Time.parse(created_at)) / 3600).round(2) 
                    else
                      'Not Merged'
                    end

    csv << [pr_number, author, author_id, merged_by, merged_by_id, additions, deletions, created_at, merged_at, time_to_merge]
  end
end

puts "Pull requests saved to pull_requests.csv"