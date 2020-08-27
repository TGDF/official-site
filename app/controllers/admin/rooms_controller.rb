# frozen_string_literal: true

module Admin
  class RoomsController < Admin::BaseController
    before_action :find_room, except: %i[index new create]

    def index
      @rooms = Room.all
    end

    def new
      @room = Room.new
    end

    def create
      @room = Room.new(room_params)
      return redirect_to(admin_rooms_path) if @room.save

      render(:new)
    end

    def edit; end

    def update
      return redirect_to(admin_rooms_path) if @room.update(room_params)

      render(:edit)
    end

    def destroy
      @room.destroy
      redirect_to(admin_rooms_path)
    end

    private

    def find_room
      @room = Room.find(params[:id])
    end

    def room_params
      params.require(:room).permit(:name, :order)
    end
  end
end
