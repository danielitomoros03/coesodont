class AddCommentToPaymentReports < ActiveRecord::Migration[7.0]
  # Observación opcional de quien reporta el pago (p. ej. «una sola transferencia por dos
  # inscripciones»), para que Control de Estudios la lea al validar.
  def change
    add_column :payment_reports, :comment, :text
  end
end
