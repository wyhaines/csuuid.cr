require "./spec_helper"


CHECKUUID = /^(........)-(....)-(....)-(....)-(............)/

describe CSUUID do
  it "creates a UUID randomly" do
    uuid = CSUUID.new
    uuid.to_s.should match CHECKUUID
  end

  it "creates a UUID from another UUID" do
    uuid_1 = CSUUID.new
    uuid_2 = CSUUID.new(uuid_1)
    uuid_1.should eq uuid_2
  end

  it "creates a UUID from another UUID string" do
    uuid_1 = CSUUID.new
    uuid_2 = CSUUID.new(uuid_1.to_s)
    uuid_1.should eq uuid_2
  end

  it "generates a UUID from an explicit second/nanosecond displacement" do
    uuid = CSUUID.new(seconds: 9223372036, nanoseconds: 729262400)
    uuid.to_s.should match /2b77a940-0002-25c1-7d04/
  end

  it "generates a UUID from an explicit second/nanosecond displacement and explicit identifier" do
    uuid = CSUUID.new(seconds: 9223372036, nanoseconds: 729262400, identifier: "79f659ccb685")
    uuid.to_s.should match /2b77a940-0002-25c1-7d04-79f659ccb685/
  end

  it "generates a UUID from a timestamp, with or without an explicit identifier" do
    dt = ParseDate.parse("2020/07/29 09:15:37")
    uuid = CSUUID.new(dt)
    uuid.to_s.should match /00000000-000e-d6b3-3539/

    dt = ParseDate.parse("2020/07/29 09:15:37").as(Time)
    uuid = CSUUID.new(timestamp: dt, identifier: "79f659ccb685")
    uuid.to_s.should match /00000000-000e-d6b3-3539-79f659ccb685/
  end

  it "generates a UUID from just an identifier" do
    uuid = CSUUID.new(identifier: "79f659ccb685")
    uuid.to_s.should match /-79f659ccb685/
  end

  it "accurately returns the seconds and nanoseconds encoded within the UUID" do
    uuid = CSUUID.new(seconds: 9223372036, nanoseconds: 729262400)
    uuid.seconds_and_nanoseconds.should eq({9223372036, 729262400})
  end

  it "accurately returns the timestamp encoded within the UUID" do
    uuid = CSUUID.new(ParseDate.parse("2020/07/29 09:15:37"))
    uuid.timestamp.should eq(
      ParseDate.parse("2020/07/29 09:15:37").not_nil!.in(Time::Location.local)
    )
  end
end
