require 'rails_helper'

RSpec.describe EmailSubscription, type: :model do
  it 'is valid with valid attributes' do
    subscription = build(:email_subscription)
    expect(subscription).to be_valid
  end

  it 'is invalid without an email' do
    subscription = build(:email_subscription, email: nil)
    expect(subscription).not_to be_valid
  end

  it 'is invalid with an invalid email format' do
    subscription = build(:email_subscription, email: 'invalid-email')
    expect(subscription).not_to be_valid
  end

  it 'normalizes email to lowercase' do
    subscription = create(:email_subscription, email: 'Test@Example.com')
    expect(subscription.email).to eq('test@example.com')
  end

  it 'is invalid with a duplicate email' do
    create(:email_subscription, email: 'test@example.com')
    subscription = build(:email_subscription, email: 'test@example.com')
    expect(subscription).not_to be_valid
  end

  it 'is valid without a name' do
    subscription = build(:email_subscription, name: nil)
    expect(subscription).to be_valid
  end
end 