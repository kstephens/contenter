# Provides an RFC4122-compliant random (version 4) UUID service
# for Linux ruby implementations.
module Contenter::UUID
  # Return an RFC4122-compliant random (version 4) UUID,
  # represented as a string of 36 characters.
  #
  # Possible (but unlikely!) return value:
  #   "e29fc859-8d6d-4c5d-aa5a-1ab726f4a192".
  #
  # Possible exceptions:
  #   Errno::ENOENT
  #
  # Caveat:
  #   Only works with Linux (or possibly other systems with /proc/sys/kernel/random/uuid).
  #
  def self.generate_random
    File.open("/proc/sys/kernel/random/uuid") { |fh| fh.read.chomp! }
  end
end

