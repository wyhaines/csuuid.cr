require "./spec_helper"

CHECKUUID = /^(........)-(....)-(....)-(....)-(............)/

describe CSUUID do
  it "creates a UUID randomly" do
    uuid = CSUUID.new
    uuid.to_s.should match CHECKUUID
  end

  it "to_s should function correctly" do
    uuid = CSUUID.new
    uuid.to_s.should eq "#{uuid}"
  end

  it "creates a CSUUID from another CSUUID" do
    uuid_1 = CSUUID.new
    uuid_2 = CSUUID.new(uuid_1)
    uuid_1.should eq uuid_2
  end

  it "creates a CSUUID from another CSUUID string" do
    uuid_1 = CSUUID.new
    uuid_2 = CSUUID.new(uuid_1.to_s)
    uuid_1.should eq uuid_2
  end

  it "generates a UUID from an explicit second/nanosecond displacement" do
    uuid = CSUUID.new(seconds: 9223372036, nanoseconds: 729262400)
    uuid.to_s.should match /000225c1-7d04-2b77-a940/
  end

  it "generates a UUID from an explicit second/nanosecond displacement and explicit identifier" do
    uuid = CSUUID.new(seconds: 9223372036, nanoseconds: 729262400, identifier: "79f659ccb685")
    uuid.to_s.should match /000225c1-7d04-2b77-a940-79f659ccb685/
  end

  it "generates a UUID from a timestamp, with or without an explicit identifier" do
    dt = ParseDate.parse("2020/07/29 09:15:37")
    uuid = CSUUID.new(dt)
    uuid.to_s.should match /000ed6b3-3539-0000-0000/

    dt = ParseDate.parse("2020/07/29 09:15:37").as(Time)
    uuid = CSUUID.new(timestamp: dt, identifier: "79f659ccb685")
    uuid.to_s.should match /000ed6b3-3539-0000-0000-79f659ccb685/
  end

  it "generates a UUID from just an identifier" do
    uuid = CSUUID.new(identifier: "79f659ccb685".hexbytes)
    uuid.to_s.should match /-79f659ccb685/
  end

  it "generates a UUID with a random identifier" do
    random_bytes = Random.new.random_bytes(6)
    uuid = CSUUID.new(identifier: random_bytes)
    uuid.to_s.should match /-#{random_bytes.hexstring}/
  end

  it "generates a UUID with the current time, but a random identifier, if initialized with no input" do
    uuid1 = CSUUID.new
    sleep 1.1
    uuid2 = CSUUID.new

    match_1 = CHECKUUID.match(uuid1.to_s)
    match_1.should_not be_nil
    match_2 = CHECKUUID.match(uuid2.to_s)
    match_2.should_not be_nil
    match_1.to_s.should_not eq match_2.to_s
    (!match_1.nil?) && (!match_2.nil?) && match_1[5].should_not eq match_2[5]
  end

  it "accurately returns the seconds and nanoseconds encoded within the UUID" do
    uuid = CSUUID.new(seconds: 9223372036, nanoseconds: 729262400)
    uuid.seconds_and_nanoseconds.should eq({9223372036, 729262400})
  end

  it "accurately returns the timestamp encoded within the UUID" do
    uuid = CSUUID.new(ParseDate.parse("2020/07/29 09:15:37"))
    uuid.timestamp.should eq(
      ParseDate.parse("2020/07/29 09:15:37").try &.in(Time::Location.local)
    )
  end

  it "can produce two unique CSUUIDs consecutively" do
    uuid1 = CSUUID.unique
    uuid2 = CSUUID.unique
    uuid1.should_not eq uuid2
  end

  it "can generate a long sequence of unique CSUUIDs" do
    uuids = CSUUID.generate(10000)
    uuids.uniq.size.should eq uuids.size
  end

  it "can compare CSUUIDs via <=>" do
    uuid1 = CSUUID.new
    uuid2 = CSUUID.new
    (uuid1 <=> uuid2).should eq -1
    (uuid2 <=> uuid1).should eq 1
    (uuid1 <=> uuid1).should eq 0
  end

  it "can compare CSUUIDs via <" do
    uuid1 = CSUUID.new
    uuid2 = CSUUID.new
    (uuid1 < uuid2).should be_true
    (uuid2 < uuid1).should be_false
  end

  it "can compare CSUUIDs via >" do
    uuid1 = CSUUID.new
    uuid2 = CSUUID.new
    (uuid1 > uuid2).should be_false
    (uuid2 > uuid1).should be_true
  end

  it "can compare CSUUIDs via <=" do
    uuid1 = CSUUID.new
    uuid2 = CSUUID.new
    (uuid1 <= uuid2).should be_true
    (uuid2 <= uuid1).should be_false
    (uuid1 <= uuid1).should be_true
  end

  it "can compare CSUUIDs via >=" do
    uuid1 = CSUUID.new
    uuid2 = CSUUID.new
    (uuid1 >= uuid2).should be_false
    (uuid2 >= uuid1).should be_true
    (uuid1 >= uuid1).should be_true
  end

  it "can work with PCG32 as the generator" do
    CSUUID.prng = Random::PCG32.new
    uuid1 = CSUUID.unique
    uuid2 = CSUUID.unique
    CHECKUUID.match(uuid1.to_s).should_not be_nil
    CHECKUUID.match(uuid2.to_s).should_not be_nil
    uuid1.should_not eq uuid2
    uuid2.should be > uuid1
  end

  it "can benchmark against the system UUIDs" do
    CSUUID.prng = Random::PCG32.new

    puts

    Benchmark.ips do |benchmark|
      benchmark.report("CSUUID.unique") { CSUUID.unique }
      benchmark.report("CSUUID.new") { CSUUID.new }
      benchmark.report("UUID.v7") { UUID.v7 }
    end
  end
end
