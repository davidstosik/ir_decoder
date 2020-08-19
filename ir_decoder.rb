require "serialport"
require "timeout"

READ_TIMEOUT_MS = 500
SERIAL_PORT = "/dev/cu.SLAB_USBtoUART"
SERIAL_FREQ = 115200
READING_COUNT = 10

readings = []

SerialPort.open(SERIAL_PORT, SERIAL_FREQ) do |serial_port|
  serial_port.read_timeout = READ_TIMEOUT_MS

  puts "Purging serial..."
  serial_port.read until serial_port.eof?

  READING_COUNT.times do
    puts "Press a button on the remote."

    while serial_port.eof?; end
    puts "Reading..."

    raw_input = serial_port.read

    reading = raw_input.lines.map { |line| line.strip.to_i }

    puts reading.join(", ")
    puts "Read #{reading.count} intervals."
    puts

    readings << reading
  end
end

if readings.map(&:count).uniq.size > 1
  abort "The readings have a different number of intervals!"
end

puts "Averaging readings..."

def average(sample)
  sample.sum / sample.size
end

def standard_deviation(sample)
  average = average(sample)
  (
    sample.map do |value|
      (value - average) ** 2
    end.sum / (sample.size - 1)
  ) ** 0.5
end

def max_distance(sample)
  average = average(sample)
  sample.map do |value|
    (value - average).abs
  end.max
end

average_data = readings.transpose.map.with_index do |interval_sample, index|
  {
    average: average(interval_sample),
    max_distance: max_distance(interval_sample),
    standard_deviation: standard_deviation(interval_sample),
    silence: index.odd? # the first interval (0) is preceded by silence
  }
end

sorted_average_data = average_data.sort_by { |ad| ad[:average] }

normalizing_max_distance = average_data.map{|max_distance:, **_|max_distance}.max * 1.5 # arbitrary

normalized_intervals = sorted_average_data.inject([]) do |normalized_intervals, average:, silence:, **_|
  normalized_interval = normalized_intervals.find do |normalized_interval|
    normalized_interval[:silence] == silence &&
      (normalized_interval[:average] - average).abs < normalizing_max_distance
  end
  unless normalized_interval
    normalized_interval = { values: [], silence: silence }
    normalized_intervals << normalized_interval
  end
  normalized_interval[:values] << average
  normalized_interval[:average] = average(normalized_interval[:values])

  normalized_intervals
end

normalized_intervals.each.with_index do |interval, index|
  interval[:letter] = (?A..?Z).to_a[index]
  interval[:letter].downcase! if interval[:silence]
end

puts "Normalized values:"
normalized_intervals.each do |values:, silence:, average:, letter:|
  puts "#{letter}. #{average}us #{silence ? "silence" : "noise"}"
end
puts "(normalizing max distance <= #{normalizing_max_distance})"

normalized_strings = readings.map do |reading|
  reading.map.with_index do |interval, index|
    normalized_intervals.find do |average:, silence:, **_|
      silence == index.odd? &&
        (interval - average).abs <= normalizing_max_distance
    end[:letter]
  end.join
end

if normalized_strings.uniq.size > 1
  abort "Normalizing the #{readings.size} readings leads to different strings!"
end

puts
puts "All readings match the same normalized string!"
puts normalized_strings.first
