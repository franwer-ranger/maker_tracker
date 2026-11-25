# Adjuntos (MT-96): capturas, vídeos y archivos de una historia o de una página
# de la documentación, en Active Storage (servicio `local`: storage/attachments,
# el volumen que copia bin/backup). Se suben con `attach_file!`, que comprueba
# tamaño y tipo antes de guardar nada y deja su evento `attachment.added`.
#
# El enlace que se pega en el markdown es relativo (/rails/active_storage/…):
# vale igual por la tailnet que por internet. Las imágenes y los vídeos van con
# `![]()` y se ven en línea; el resto con `[]()` y se descarga. Active Storage
# nunca sirve en línea un HTML ni un SVG (content_types_allowed_inline): bajan
# como descarga. Por eso un SVG, y un HEIC (que no pintan Chrome ni Firefox), se
# admiten pero van como archivo, no como imagen en línea.
module Attachable
  extend ActiveSupport::Concern

  MAX_SIZE = 100.megabytes
  INLINE_IMAGE_TYPES = %w[image/png image/jpeg image/gif image/webp image/avif].freeze
  IMAGE_TYPES = (INLINE_IMAGE_TYPES + %w[image/svg+xml image/heic]).freeze
  VIDEO_TYPES = %w[video/mp4 video/webm video/quicktime].freeze
  FILE_TYPES = %w[application/pdf text/plain text/markdown text/csv text/html application/json application/zip application/gzip application/x-tar].freeze
  ALLOWED_TYPES = (IMAGE_TYPES + VIDEO_TYPES + FILE_TYPES).freeze
  # Un adjunto citado por su nombre en el markdown (MT-122): `![pie](attachment:captura.png)`.
  REFERENCE = /(!?\[[^\]]*\]\()attachment:([^)\s]+)\)/

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
      raise Invalid.new("#{filename} ocupa #{Attachable.human_size(size)}: el máximo es #{Attachable.human_size(MAX_SIZE)}.",
        "#{filename} is #{Attachable.human_size(size)}: the limit is #{Attachable.human_size(MAX_SIZE)}.")
    end

    type = Marcel::MimeType.for(io, name: filename, declared_type: content_type)
    io.rewind if io.respond_to?(:rewind)
    unless ALLOWED_TYPES.include?(type)
      raise Invalid.new("#{filename} es #{type}, un tipo que no se admite: imágenes, vídeos, PDF, texto o comprimidos.",
        "#{filename} is #{type}, which is not allowed: images, videos, PDF, text or archives.")
    end

    blob = ActiveStorage::Blob.create_and_upload!(io: io, filename: filename, content_type: type, identify: false)
    transaction do
      # Sobre un registro guardado, `attach` lo guarda: false si no es válido.
      attachments.attach(blob) || raise(ActiveRecord::RecordInvalid, self)
      record_event!("attachment.added", actor: actor, story: (self if is_a?(Story)),
        data: { filename: blob.filename.to_s, content_type: type, byte_size: blob.byte_size, page_id: (id if is_a?(Page)), slug: (slug if is_a?(Page)) }.compact)
    end
    attachments_attachments.find_by!(blob: blob)
  rescue ActiveRecord::RecordInvalid
    blob&.purge
    raise
  end

  # Los adjuntos, en el orden en que se subieron.
  def ordered_attachments = attachments_attachments.includes(:blob).order(:created_at, :id)

  # El markdown con sus referencias por nombre (MT-122) resueltas a su enlace:
  # `![pie](attachment:captura.png)` → `![pie](/rails/active_storage/…/captura.png)`.
  # Si hay dos con el mismo nombre, vale el último que se subió. La que no
  # existe se queda como está: la UI la pinta como «Falta la imagen …».
  # `links:` (opcional) es el `attachment_links` ya calculado, para no repetirlo.
  def resolve_attachment_references(text, links: nil)
    return text if text.blank? || !text.include?("attachment:")

    links ||= attachment_links
    text.gsub(REFERENCE) { (link = links[Attachable.decode_name($2)]) ? "#{$1}#{link})" : $& }
  end

  # Nombre → enlace de cada adjunto (el último si se repite): con lo que la web
  # resuelve `attachment:` al pintar el markdown en el navegador.
  def attachment_links = ordered_attachments.to_h { [ it.filename.to_s, Attachable.link(it) ] }

  # Las imágenes adjuntas que se ven en línea, en el orden en que se subieron:
  # las capturas de la portada (MT-102) y de «El recorrido» de una capacidad (MT-103).
  def screenshots = ordered_attachments.select { INLINE_IMAGE_TYPES.include?(it.content_type) }

  # "![captura.png](/rails/active_storage/blobs/redirect/…/captura.png)"
  def self.markdown(attachment)
    name = attachment.filename.to_s.gsub(/[\[\]]/, "")
    inline?(attachment.content_type) ? "![#{name}](#{link(attachment)})" : "[#{name}](#{link(attachment)})"
  end

  # La misma línea con el adjunto por su nombre (MT-122), la que imprime `mt attach`:
  # "![captura.png](attachment:captura.png)", o "![pie](attachment:captura.png)" con `alt`.
  def self.reference(attachment, alt: nil)
    filename = attachment.filename.to_s
    text = (alt.presence || filename).to_s.gsub(/[\[\]\n]/, "")
    name = filename.gsub("%", "%25").gsub(" ", "%20").gsub("(", "%28").gsub(")", "%29")
    inline?(attachment.content_type) ? "![#{text}](attachment:#{name})" : "[#{text}](attachment:#{name})"
  end

  # "captura%20(2).png" → "captura (2).png"; con un `%` mal escrito ("100%.png"), tal cual.
  def self.decode_name(name)
    URI.decode_uri_component(name)
  rescue ArgumentError
    name
  end

  # El enlace con los paréntesis escapados, para que no corten el `()` del markdown.
  def self.link(attachment) = path(attachment).gsub("(", "%28").gsub(")", "%29")

  # Se ve en la página (imagen o vídeo) en vez de descargarse.
  def self.inline?(content_type) = (INLINE_IMAGE_TYPES + VIDEO_TYPES).include?(content_type)

  # El enlace estable del adjunto (redirige al archivo), relativo a la instancia.
  def self.path(attachment) = Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)

  # "120 KB"
  def self.human_size(bytes) = ActiveSupport::NumberHelper.number_to_human_size(bytes, locale: :en)
end
