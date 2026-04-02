# frozen_string_literal: true

module Admin
  module FlashHelper
    FLASH_STYLES = {
      "alert" => {
        bg: "bg-red-50",
        border: "border-red-500",
        text: "text-red-800",
        icon_color: "text-red-500",
        icon: "fa-times-circle",
        aria_live: "assertive"
      },
      "notice" => {
        bg: "bg-green-50",
        border: "border-green-500",
        text: "text-green-800",
        icon_color: "text-green-500",
        icon: "fa-check-circle",
        aria_live: "polite"
      },
      "warning" => {
        bg: "bg-yellow-50",
        border: "border-yellow-500",
        text: "text-yellow-800",
        icon_color: "text-yellow-500",
        icon: "fa-exclamation-triangle",
        aria_live: "polite"
      }
    }.freeze

    DEFAULT_STYLE = {
      bg: "bg-blue-50",
      border: "border-blue-500",
      text: "text-blue-800",
      icon_color: "text-blue-500",
      icon: "fa-info-circle",
      aria_live: "polite"
    }.freeze

    def admin_flash_style(type)
      FLASH_STYLES.fetch(type.to_s, DEFAULT_STYLE)
    end
  end
end
