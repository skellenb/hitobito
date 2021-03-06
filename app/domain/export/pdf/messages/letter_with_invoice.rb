# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Messages
  class LetterWithInvoice < Letter

    def filename
      super do |parts|
        parts.prepend Invoice.model_name.human.downcase
      end
    end

    def render_sections(pdf, recipient)
      super
      render_payment_slip(pdf, recipient)
    end

    def render_payment_slip(pdf, recipient)
      invoice = @letter.invoice_for(recipient)
      if invoice.qr?
        Export::Pdf::Invoice::PaymentSlipQr.new(pdf, invoice).render
      else
        ocrb_path = Rails.root.join('app', 'javascript', 'fonts', 'OCRB.ttf')
        pdf.font_families.update('ocrb' => { normal: ocrb_path })
        Export::Pdf::Invoice::PaymentSlip.new(pdf, invoice).render
      end
    end
  end
end
