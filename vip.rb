require 'csv'

class Voter
  attr_accessor :street, :apt, :city, :state, :zip, :precinct_id

  def initialize(options = {})
    self.street = options["street"]
    self.apt = options["apt"]
    self.city = options["city"]
    self.state = options["state"]
    self.zip = options["zip"]
    self.precinct_id = options["precinct_id"]
  end
end

class Vip

  attr_reader :polls_file, :voter_file, :output_file
  attr_reader :voters, :polls


  def initialize(files = [])
    @voter_file = files[0] ||= "voter_poll_join/voter_file.csv"
    @polls_file = files[1] ||= "voter_poll_join/precinct_polling_list.csv"
    @output_file = files[2] ||= "output.csv"
    @polls = []
    @voters = []
  end

  def run!
    parse_voters
    parse_polls
  end

  protected

  def parse_voters
    CSV.foreach(self.voter_file, headers: true) do |row|

      # TODO: do the voter processing
      voter_attributes = normalize_row!(row)
      
      precinct_fips, precinct_num = voter_attributes["precinct_id"].split("-")

      voter_attributes['state_fips'] = precinct_fips
      voter_attributes['precinct_num'] = precinct_num
      voter_attributes["precinct_id"] = [voter_attributes["state"], precinct_num].join("-")

      @voters << Voter.new(voter_attributes)
    end
    puts @voters.first.inspect
  end

  def parse_polls
    CSV.foreach(self.polls_file, headers: true) do |row|

      poll_attributes = normalize_row!(row, {prefix: "poll"})

      
      state_and_zip = poll_attributes.delete("poll_state/zip")
      
      poll_attributes["poll_state"] = state_and_zip.split(" ").first
      poll_attributes["poll_zip"] = state_and_zip.split(" ").last

      poll_attributes["poll_precinct_state"] = poll_attributes["poll_precinct"].split("-").first
      poll_attributes["poll_precinct_num"] = poll_attributes["poll_precinct"].split("-").last.rjust(3, "0")

      poll_attributes["poll_precinct_id"] = [poll_attributes["poll_state"], poll_attributes["poll_precinct_num"]].join("-")

      @polls << poll_attributes
    end

    
  end

  def normalize_row!(csv_row, options = {})

    normalized_hash = {}
    csv_row.to_hash.each_pair do |k,v|
      
      new_key = [options[:prefix], k.downcase.gsub(" ", "_")].compact.join("_")
      
      normalized_hash.merge!({new_key => v}) 
      
    end
    return normalized_hash
  end
end



vip = Vip.new(ARGV)

vip.run!


