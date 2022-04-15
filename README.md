# CSUUID

![CSUUID CI](https://img.shields.io/github/workflow/status/wyhaines/CSUUID.cr/CSUUID.cr%20CI?style=for-the-badge&logo=GitHub)
[![GitHub release](https://img.shields.io/github/release/wyhaines/CSUUID.cr.svg?style=for-the-badge)](https://github.com/wyhaines/CSUUID.cr/releases)
![GitHub commits since latest release (by SemVer)](https://img.shields.io/github/commits-since/wyhaines/CSUUID.cr/latest?style=for-the-badge)

This struct wraps up a UUID that encodes a timestamp measured as seconds from the epoch `(0001-01-01 00:00:00.0 UTC)` observed at the location where the timestamp was generated, plus nanoseconds in the current second, plus 6 bytes for unique identification of the source -- this could be an IPV4 address with two null bytes, a MAC address, or some other sequence that will fit in 6 bytes.
  
Nanoseconds will fit in an Int32 (4 bytes), but seconds since the epoch will not. The current number of seconds leaks a short distance into a 5th byte, meaning that in this class, it has to be represented by an Int64. This is problematic because a UID allows for 16 bytes, so the use of 8 for seconds and 4 for nanoseconds leaves only 4 bytes for system identification. It also leaves three bytes in the UUID as zeros because 8 bytes for seconds is a lot of seconds.
    
One solution is to combine the seconds and the nanoseconds into a single Int64 number. This requires math operations to do efficiently:

```
(seconds * 1000000000) + nanoseconds
```

and then more math to extract the original numbers in order to reconstruct the original timestamp. This leaves 8 bytes for identification or other uniqueness information, which is lovely, but the math requirement is less lovely.
  
The other options is to truncate 2 bytes off of the seconds, storing 6 bytes of seconds data. This leaves 6 bytes for identification.
    
The current implementation chose option #2, as it is less work to generate a UUID if math is not involved.

``` 
+-------------+-----------------+------------+
| nanoseconds |     seconds     | identifier |
|    0..3     |      4..10      |   11..15   |
+-------------+-----------------+------------+
```

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     csuuid:
       github: wyhaines/csuuid.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "csuuid"

uuid = CSUUID.new

uuid = CSUUID.new(seconds: 9223372036, nanoseconds: 729262400)

uuid = CSUUID.new(identifier: Random.new.random_bytes(6))

dt = ParseDate.parse("2020/07/29 09:15:37")
uuid = CSUUID.new(dt)
```

## API Docs

https://wyhaines.github.io/csuuid.cr/

## Contributing

1. Fork it (<https://github.com/wyhaines/csuuid.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/wyhaines/CSUUID.cr?style=for-the-badge)
![GitHub issues](https://img.shields.io/github/issues/wyhaines/CSUUID.cr?style=for-the-badge)