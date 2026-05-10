# frozen_string_literal: true
require "encryption"

class User < ApplicationRecord
  attr_accessor :password, :password_confirmation

  validates :password, presence: true,
                       confirmation: true,
                       length: {within: 6..40},
                       on: :create,
                       if: :password

  validates_presence_of :email
  validates_uniqueness_of :email
  validates_format_of :email, with: /.+@.+\..+/i

  has_one :retirement, dependent: :destroy
  has_one :paid_time_off, dependent: :destroy
  has_one :work_info, dependent: :destroy
  has_many :performance, dependent: :destroy
  has_many :pay, dependent: :destroy
  has_many :messages, foreign_key: :receiver_id, dependent: :destroy

  before_save :hash_password
  after_create { generate_token(:auth_token) }
  before_create :build_benefits_data

  def build_benefits_data
    build_retirement(POPULATE_RETIREMENTS.sample)
    build_paid_time_off(POPULATE_PAID_TIME_OFF.sample).schedule.build(POPULATE_SCHEDULE.sample)
    build_work_info(POPULATE_WORK_INFO.sample)
    # Uncomment below line to use encrypted SSN(s)
    #work_info.build_key_management(:iv => SecureRandom.hex(32))
    performance.build(POPULATE_PERFORMANCE.sample)
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  private

  def self.authenticate(email, password)
  user = find_by_email(email)
  if user and user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
  else
      raise "Invalid Credentials Supplied"
  end
  end

  def hash_password
    if self.password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(self.password, self.password_salt)
    end
  end

  def generate_token(column)
    loop do
      self[column] = Encryption.encrypt_sensitive_value(self.id)
      break unless User.exists?(column => self[column])
    end

    self.save!
  end
end
