struct CSUUID
  {% begin %}
    VERSION = {{ read_file("#{__DIR__}/../VERSION").chomp }}
    {% end %}
end
