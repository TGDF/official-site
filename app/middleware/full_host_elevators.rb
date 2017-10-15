class FullHostElevators < Apartment::Elevators::Generic
  def call(*args)
    super
  rescue Apartment::TenantNotFound
    Apartment::Tenant.switch!
    @app.call(*args)
  end

  def parse_tenant_name(request)
    return nil if request.host.blank?

    request.host.tr('.', '_')
  end
end
