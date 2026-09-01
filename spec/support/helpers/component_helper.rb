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

    # Renders lazily so the component instance is rendered exactly once per
    # example: ViewComponent raises ReusedInstanceError on a second render, and
    # a lazy subject also lets `before` hooks set up time or state that the
    # render must observe.
    def when_rendered(url: '/')
      let(:render_url) { url }

      subject do
        with_request_url(render_url) { render_inline(component) }
        page
      end
    end
  end
end
