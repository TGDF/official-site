# frozen_string_literal: true

module Admin
  class AgendaTagsController < Admin::BaseController
    before_action :find_agenda_tag, except: %i[index new create]

    def index
      @agenda_tags = AgendaTag.all
    end

    def new
      @agenda_tag = AgendaTag.new
    end

    def create
      Mobility.with_locale(I18n.default_locale) do
        @agenda_tag = AgendaTag.new(agenda_tag_params)
        return redirect_to(admin_agenda_tags_path) if @agenda_tag.save

        render :new
      end
    end

    def edit; end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to(admin_agenda_tags_path) if @agenda_tag.update(agenda_tag_params)

        render :edit
      end
    end

    def destroy
      @agenda_tag.destroy
      redirect_to(admin_agenda_tags_path)
    end

    private

    def find_agenda_tag
      @agenda_tag = AgendaTag.find(params[:id])
    end

    def agenda_tag_params
      params.require(:agenda_tag).permit(:name)
    end
  end
end
