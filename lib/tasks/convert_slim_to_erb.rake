# frozen_string_literal: true

namespace :admin do
  desc "Convert Slim syntax in +v1.erb files to proper ERB syntax"
  task convert_slim_to_erb: :environment do
    require "fileutils"

    # Find all +v1.erb files that contain Slim syntax
    pattern = Rails.root.join("app", "views", "admin", "**", "*+v1.erb")
    files = Dir.glob(pattern)

    puts "Found #{files.length} +v1.erb files to process"

    converted_count = 0

    files.each do |file_path|
      content = File.read(file_path)

      # Skip if already converted (doesn't contain Slim syntax markers)
      next unless content.include?("CONVERTED FROM SLIM - NEEDS MANUAL ERB CONVERSION") ||
                  content.match?(/^[a-z]+\.[a-z-]+/) || # CSS class syntax like div.class
                  content.match?(/^\s*\/\s/) || # Slim comments
                  content.match?(/^\s*[=-]\s/) # Slim output/code syntax

      puts "Converting: #{file_path}"

      # Basic Slim to ERB conversion
      converted_content = convert_slim_to_erb(content)

      # Write back to file
      File.write(file_path, converted_content)
      converted_count += 1
    end

    puts "Converted #{converted_count} files from Slim to ERB syntax"
  end

  private

  def convert_slim_to_erb(content)
    lines = content.split("\n")
    converted_lines = []

    lines.each do |line|
      # Skip the conversion marker
      next if line.include?("CONVERTED FROM SLIM - NEEDS MANUAL ERB CONVERSION")

      # Handle Slim comments (/ comment) -> (<%# comment %>)
      if line.match?(/^\s*\/\s(.*)$/)
        converted_lines << line.gsub(/^(\s*)\/\s(.*)$/, '\1<%# \2 %>')
        next
      end

      # Handle Slim output (= code) -> (<%= code %>)
      if line.match?(/^(\s*)=\s(.*)$/)
        converted_lines << line.gsub(/^(\s*)=\s(.*)$/, '\1<%= \2 %>')
        next
      end

      # Handle Slim code (- code) -> (<% code %>)
      if line.match?(/^(\s*)-\s(.*)$/)
        converted_lines << line.gsub(/^(\s*)-\s(.*)$/, '\1<% \2 %>')
        next
      end

      # Handle HTML tags with CSS classes (tag.class -> <tag class="class">)
      if line.match?(/^(\s*)([a-z]+)\.([a-z0-9-_.]+)(\s*.*)?$/)
        line = line.gsub(/^(\s*)([a-z]+)\.([a-z0-9-_.]+)(\s*.*)?$/) do
          indent = $1
          tag = $2
          classes = $3.gsub(".", " ")
          rest = $4 || ""

          if rest.strip.empty?
            "#{indent}<#{tag} class=\"#{classes}\">"
          else
            "#{indent}<#{tag} class=\"#{classes}\">#{rest}"
          end
        end
      end

      # Handle HTML tags with attributes in parentheses
      if line.match?(/^(\s*)([a-z]+)(\([^)]+\))(\s*.*)?$/)
        line = line.gsub(/^(\s*)([a-z]+)\(([^)]+)\)(\s*.*)?$/) do
          indent = $1
          tag = $2
          attrs = $3
          rest = $4 || ""

          # Convert Slim attribute syntax to HTML
          html_attrs = attrs.gsub(/(\w+):\s*'([^']*)'/, '\1="\2"')
                           .gsub(/(\w+):\s*"([^"]*)"/, '\1="\2"')
                           .gsub(/(\w+):\s*([^,\s)]+)/, '\1="\2"')

          if rest.strip.empty?
            "#{indent}<#{tag} #{html_attrs}>"
          else
            "#{indent}<#{tag} #{html_attrs}>#{rest}"
          end
        end
      end

      # Handle text interpolation (| text #{var}) -> (text <%= var %>)
      line = line.gsub(/\|\s*(.*)$/, '\1')
                .gsub(/#\{([^}]+)\}/, '<%= \1 %>')

      converted_lines << line
    end

    converted_lines.join("\n") + "\n"
  end
end
