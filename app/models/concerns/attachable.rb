# Adjuntos (MT-96): capturas, vídeos y archivos de una historia o de una página
# de la documentación, en Active Storage (servicio `local`: storage/attachments,
# el volumen que copia bin/backup). Se suben con `attach_file!`, que comprueba
# tamaño y tipo antes de guardar nada y deja su evento `attachment.added`.
#
# El enlace que se pega en el markdown es relativo (/rails/active_storage/…):
# vale igual por la tailnet que por internet. Las imágenes y los vídeos van con
# `![]()` y se ven en línea; el resto con `[]()` y se descarga. Active Storage
# nunca sirve en línea un HTML ni un SVG (content_types_allowed_inline): bajan
# como descarga.
module Attachable
  extend ActiveSupport::Concern

  MAX_SIZE = 100.megabytes
  IMAGE_TYPES = %w[image/png image/jpeg image/gif image/webp image/avif image/svg+xml image/heic].freeze
  VIDEO_TYPES = %w[video/mp4 video/webm video/quicktime].freeze
  FILE_TYPES = %w[application/pdf text/plain text/markdown text/csv text/html application/json application/zip application/gzip application/x-tar].freeze
  ALLOWED_TYPES = (IMAGE_TYPES + VIDEO_TYPES + FILE_TYPES).freeze

  # El archivo no es válido: vacío, demasiado grande o de un tipo que no se
  # admite. `message` va en castellano (la UI) y `english` en inglés (la API).
  class Invalid < ArgumentError
    attr_reader :english

    def initialize(spanish, english)
      @english = english
      super(spanish)
    end
  end

  included do
    # `thumb`: la miniatura de una imagen (image_processing con libvips, que
    # trae la imagen de Docker). Se genera la primera vez que se pide.
    has_many_attached :attachments do |attachable|
      attachable.variant :thumb, resize_to_limit: [ 640, 640 ]
    end
  end

  # Sube `io` (un archivo abierto o un ActionDispatch::Http::UploadedFile) y lo
  # adjunta. Devuelve el adjunto. Invalid si no cabe o no se admite.
  def attach_file!(io, filename:, actor:, content_type: nil)
    filename = ActiveStorage::Filename.new(filename.to_s).sanitized
    raise Invalid.new("El archivo no tiene nombre.", "the file has no name.") if filename.blank?

    size = io.size
    raise Invalid.new("#{filename} está vacío.", "#{filename} is empty.") if size.zero?
    if size > MAX_SIZE
      raise Invalid.new("#{filename} ocupa #{human_size(size)}: el máximo es #{human_size(MAX_SIZE)}.",
        "#{filename} is #{human_size(size)}: the limit is #{human_size(MAX_SIZE)}.")
    end

    type = Marcel::MimeType.for(io, name: filename, declared_type: content_type)
    io.rewind if io.respond_to?(:rewind)
    unless ALLOWED_TYPES.include?(type)
      raise Invalid.new("#{filename} es #{type}, un tipo que no se admite: imágenes, vídeos, PDF, texto o comprimidos.",
        "#{filename} is #{type}, which is not allowed: images, videos, PDF, text or archives.")
    end

    blob = ActiveStorage::Blob.create_and_upload!(io: io, filename: filename, content_type: type, identify: false)
    transaction do
      attachments.attach(blob)
      record_event!("attachment.added", actor: actor, story: (self if is_a?(Story)),
        data: { filename: blob.filename.to_s, content_type: type, byte_size: blob.byte_size, page_id: (id if is_a?(Page)), slug: (slug if is_a?(Page)) }.compact)
    end
    attachments_attachments.find_by!(blob: blob)
  end

  # Las imágenes adjuntas, en el orden en que se subieron: las capturas de la
  # portada (MT-102) y de «El recorrido» de una capacidad (MT-103).
  def screenshots = attachments_attachments.includes(:blob).order(:created_at, :id).select { IMAGE_TYPES.include?(it.content_type) }

  # "![captura.png](/rails/active_storage/blobs/redirect/…/captura.png)"
  def self.markdown(attachment)
    name = attachment.filename.to_s.gsub(/[\[\]]/, "")
    link = path(attachment).gsub("(", "%28").gsub(")", "%29")
    inline?(attachment.content_type) ? "![#{name}](#{link})" : "[#{name}](#{link})"
  end

  # Se ve en la página (imagen o vídeo) en vez de descargarse.
  def self.inline?(content_type) = (IMAGE_TYPES + VIDEO_TYPES).include?(content_type)

  # El enlace estable del adjunto (redirige al archivo), relativo a la instancia.
  def self.path(attachment) = Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)

  private

  def human_size(bytes) = ActiveSupport::NumberHelper.number_to_human_size(bytes, locale: :en)
end
