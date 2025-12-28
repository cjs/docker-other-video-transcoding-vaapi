#!/usr/bin/env ruby
#
# batch.rb
#

QUEUE_PATH = '/mnt/media/queue.txt'

while true
  content = File.read(QUEUE_PATH)
  input = content.match(/^.*\R/).to_s.chomp

  break if input.empty?

  queue = File.new(QUEUE_PATH, 'wb')
  queue.print content.sub(/^.*\R/, '')
  queue.close

  break unless system('/app/other-transcode.rb', *ARGV, input)
end
