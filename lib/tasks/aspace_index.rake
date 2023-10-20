# frozen_string_literal:true

# what does the csv look like?
#  fields in the top line
#  what about multiple values? pipe as a delimiter
#  worktype in the first col, eg generic, image ...
#  filenames in the second col
#  id in the third col, omit "oregondigital:"
#  if read_groups is included, this will override the default of public
#  if admin_set_id is included, it will override admin_set/default
# args: path to dir containing all files including csv, name of the csv, email
# called like this: rake oregon_digital:csv_ingest csv=mymetadata.csv filedir=/data/allthefiles email=admin@example.org

WORKTYPE = 0
FILENAMES = 1
ID = 2
SKIPTO = 3

namespace :arclight_osu do
  desc 'ingest works using csv'
  task aspace_index: :environment do
    @base_url = URI(ENV.fetch('ARCHIVESSPACE_URL', 'https://sandbox.archivesspace.org/staff/api/'))
    process
  end
end

def process
  # Get all repositories
  # For each repository get all resources
  #   For each resource
  #     Get resource id
  #     Get EAD xml description by resource id & repository id
  #     Index EAD into Solr

  repositories.each do |repo|
    repo_id = repo['position']
    ids = get_repository_resource_ids(repo_id)
    ids.each do |id|
      xml = get_resource_ead_xml(repo_id, id)
      ead_xml = Nokogiri::XML(xml)

      # EAD must have an eadid to index correctly
      next unless validate_ead_id_exists(ead_xml)

      index_ead(xml)
    end
  end
end

# Fetch and store the session token for ArchivesSpace API
def session_token
  return @session_token if @session_token

  user = ENV.fetch('ARCHIVESSPACE_API_USER', 'admin')
  password = ENV.fetch('ARCHIVESSPACE_API_PASS', 'admin')
  path = "users/#{user}/login"
  params = { password: }

  res = Net::HTTP.post_form(@base_url + path, params)
  json = JSON.parse(res.body)

  @session_token = json['session']
end

# Get all repositories
def repositories
  path = 'repositories'
  headers = { 'X-ArchivesSpace-Session': session_token }

  res = Net::HTTP.get_response(@base_url + path, headers)
  JSON.parse(res.body)
end

# Get all resource IDs in a repository
# TODO: shorten response to only IDs which have changed since last run
def get_repository_resource_ids(repo_id)
  path = "repositories/#{repo_id}/resources?all_ids=true"
  headers = { 'X-ArchivesSpace-Session': session_token }

  res = Net::HTTP.get_response(@base_url + path, headers)
  JSON.parse(res.body)
end

# Fetch an EAD2002 xml for the resource
def get_resource_ead_xml(repo_id, id)
  path = "repositories/#{repo_id}/resource_descriptions/#{id}.xml?include_daos=true&ead3=false"
  headers = { 'X-ArchivesSpace-Session': session_token }

  res = Net::HTTP.get_response(@base_url + path, headers)
  res.body
end

# Make sure the EAD has an eadid field
# TODO: Consider adding a mock eadid to ensure resource is index?
def validate_ead_id_exists(xml)
  eadid = xml.at_css('ead eadheader eadid')
  return true if eadid && eadid.text.length.positive?

  title = ead_xml.at_css('ead archdesc did unittitle').text
  puts "EADID does not exist for #{title}"
  false
end

def index_ead(xml)
  tmp = Tempfile.new(["#{Time.now.to_i}-", '.xml'], encoding: 'ascii-8bit')
  tmp.write xml
  ENV['FILE'] = tmp.path
  tmp.close
  Rake::Task['arclight:index'].invoke
  Rake::Task['arclight:index'].reenable
ensure
  tmp.delete
end

def create_logger
  datetime_today = Time.now.strftime('%Y%m%d%H%M%S') # "20171021125903"
  ActiveSupport::Logger.new("#{Rails.root}/log/csv_ingest_job-#{datetime_today}.log")
end
