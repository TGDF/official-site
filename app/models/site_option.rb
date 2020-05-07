# frozen_string_literal: true

require 'singleton'

class SiteOption
  class << self
    delegate_missing_to :instance
  end

  include Singleton
  include Enumerable

  delegate :each, to: :@options

  def initialize
    @options = config.map do |group, options|
      options.map { |option| format_option(group, option) }
    end.flatten
  end

  def attribute_names
    @attribute_names ||= @options.map { |option| option[:name] }
  end

  def config
    Rails.application.config_for(:site_options)
  end

  private

  def format_option(group, option)
    option.symbolize_keys.merge(
      name: :"#{group}_#{option['name']}",
      type: option['type'].to_sym
    )
  end
end
