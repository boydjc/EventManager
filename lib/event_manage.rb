require 'csv'
require 'google/apis/civicinfo_v2'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

def clean_zipcode(zipcode)
  if zipcode.nil?
    zipcode = '00000'
  elsif zipcode.length < 5
    zipcode = zipcode.rjust(5, '0')
  elsif zipcode.length > 5
    zipcode = zipcode[0..4]
  end
  return zipcode
end

puts "Event Manager Initialized!"

contents = CSV.open('event_attendees.csv', 
                    headers: true,
					header_converters: :symbol)
contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])

  begin
    legislators = civic_info.representative_info_by_address(
	  address: zipcode,
	  levels: 'country',
	  roles: ['legislatorUpperBody', 'legislatorLowerBody']
	)
  rescue
    'You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials'
  end

  puts "#{name} #{zipcode} #{legislators}"
end
