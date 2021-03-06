class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :async

  has_many :wiki_motions
  has_many :policies
  has_many :watches

  validates :name, presence: true, uniqueness: true

  def password_required?
    name != User.system_name
  end

  def email_required?
    name != User.system_name
  end

  def api_key
    api_key = read_attribute(:api_key) || User.random_api_key
    update_attribute(:api_key, api_key)
    api_key
  end

  def policies_watched
    watches.where(watchable_type: 'Policy').map { |w| Policy.find(w.watchable_id)  }
  end

  def watching?(object)
    !!watches.find_by(watchable_type: object.class, watchable_id: object.id)
  end

  def toggle_policy_watch(policy)
    if watch = policy.watches.find_by(user: self)
      watch.destroy!
    else
      policy.watches.create!(user: self)
    end
  end

  def recent_changes(size)
    changes = PaperTrail::Version.order(created_at: :desc).where(whodunnit: self).limit(size) +
              WikiMotion.order(created_at: :desc).where(user: self).limit(size)
    changes.sort_by {|v| -v.created_at.to_i}.take(size)
  end

  def self.system_name
    "system"
  end

  # System user - used when updating divisions from a rake task
  def self.system
    find_or_create_by!(name: system_name)
  end

  def self.random_api_key
    Digest::MD5.base64digest(rand.to_s + Time.now.to_s)[0...20]
  end
end
