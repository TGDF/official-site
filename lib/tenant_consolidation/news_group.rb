# frozen_string_literal: true

module TenantConsolidation
  # The news group. Every news item moves as it is: its content keeps the /uploads/
  # urls it embeds, which stay readable because consolidation deletes no file, and
  # its author keeps the AdminUser id it names — AdminUser already lives in public,
  # so that id means the same person after the move. An author of any other type
  # would name a tenant row the move renumbers, so it is refused; so are two items
  # of a site sharing a slug.
  module NewsGroup
    extend Group

    NAME = "news"
    MODELS = %w[News].freeze
    UPLOADS = { "News" => :thumbnail }.freeze

    module_function

    def plan(site)
      problems = foreign_authors(site) + Plan.slug_clashes(site, "News")
      raise Plan::Invalid, problems.join("; ") if problems.any?

      Plan.carry(site, MODELS)
    end

    def foreign_authors(site)
      site.rows("News").reject { |row| [ nil, "AdminUser" ].include?(row.attributes["author_type"]) }.map do |row|
        "#{site.tenant_name} News##{row.id} has a #{row.attributes['author_type']} author, not an AdminUser"
      end
    end
  end
end
