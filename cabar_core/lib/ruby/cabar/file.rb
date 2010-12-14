=begin rdoc

Extensions for Ruby File for Cabar.

=end

class ::File
  # Iteratively expands symlinks; handles relative links.
  # Returns an absolute path
  #
  # DOES NOT WORK CORRECTLY ON
  def self.cabar_expand_symlink orig_file, limit = 20
    file = orig_file

    file = File.expand_path(file)

    while File.symlink? file
      if (limit -= 1) < 0
        raise ArgumentError, "infinite symlink loop for #{orig_file.inspect}?"
      end

      link = File.readlink(file)

      # If the link is absolute,
      #   leave it alone,
      # Otherwise,
      #   It is relative to the directory of the link name.
      file = File.expand_path(link, File.dirname(file))
    end

    file
  end
end

