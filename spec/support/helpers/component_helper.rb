# frozen_string_literal: true

module ComponentHelper
  extend ActiveSupport::Concern

  class_methods do
    def given_a_component(**args, &block)
      if block.nil?
        let(:component) { described_class.new(**args) }
      else
        let(:component) { instance_exec(&block) }
      end
    end

    def when_rendered(url: '/')
      subject { page }

      before { with_request_url(url) { render_inline(component) } }
    end
  end
end
