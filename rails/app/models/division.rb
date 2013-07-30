class Division < ActiveRecord::Base
  self.table_name = "pw_division"

  has_one :division_info

  delegate :rebellions, :turnout, :aye_majority, to: :division_info
  alias_attribute :date, :division_date
  alias_attribute :name, :division_name
  alias_attribute :number, :division_number

  scope :in_house, ->(house) { where(house: house) }
  scope :in_australian_house, ->(australian_house) { in_house(Division.australian_to_uk_house(australian_house)) }
  # TODO This doesn't exactly match the wording in the interface. Fix this.
  scope :with_rebellions, -> { where("rebellions > 10") }
  scope :in_parliament, ->(parliament) { where("division_date >= ? AND division_date < ?", parliament[:from], parliament[:to]) }

  def division_name
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(read_attribute(:division_name))
  end

  def oa_debate_url
    "http://www.openaustralia.org/debates/?id=#{oa_debate_id}"
  end

  def oa_debate_id
    # This probably won't generalise to the senate
    debate_gid.split("/")[2]
  end

  # This is a bit of a guess
  def majority
    aye_majority.abs
  end

  def clock_time
    text = read_attribute(:clock_time)
    Time.parse(text) if text && text != ""
  end

  def australian_house
    Division.uk_to_australian_house(house)
  end

  def australian_house_name
    australian_house.capitalize
  end

  def self.uk_to_australian_house(house)
    case house
    when "commons"
      "representatives"
    when "lords"
      "senate"
    else
      raise "Unexpected value"
    end
  end

  def self.australian_to_uk_house(australian_house)
    case australian_house
    when "representatives"
      "commons"
    when "senate"
      "lords"
    else
      raise "unexpected value"
    end
  end
end
