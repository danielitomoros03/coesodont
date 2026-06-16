# Recalcula y persiste efficiency/promedios de grades cuyo valor almacenado quedó stale.
# Origen del problema: import masivo de notas 2024 dejó grades.efficiency en 1.0 pese a tener aplazadas.
# Idempotente: solo actualiza los grades cuyo valor difiere del recalculado.
#
#   bin/rails efficiency:backfill          # aplica
#   bin/rails efficiency:backfill DRY=1    # solo reporta, no escribe
namespace :efficiency do
  desc "Recalcula efficiency/promedios de grades con valor stale"
  task backfill: :environment do
    dry = ENV["DRY"].present?
    fixed = 0
    scanned = 0
    skipped_empty = 0

    Grade.find_each do |grade|
      scanned += 1

      # Solo grades con carga cursada: los vacíos (cursados==0) darían 1.0 y solo generarían ruido nil<->1.0
      if grade.total_credits_coursed.to_i == 0
        skipped_empty += 1
        next
      end

      nueva_ef = grade.calculate_efficiency
      nuevo_sa = grade.calculate_average
      nuevo_wa = grade.calculate_weighted_average

      next if grade.efficiency == nueva_ef && grade.simple_average == nuevo_sa && grade.weighted_average == nuevo_wa

      fixed += 1
      puts "  grade ##{grade.id}: ef #{grade.efficiency.inspect} -> #{nueva_ef.inspect}"
      unless dry
        grade.update_columns(efficiency: nueva_ef, simple_average: nuevo_sa, weighted_average: nuevo_wa)
      end
    end

    puts "#{dry ? '[DRY] ' : ''}Escaneados: #{scanned} | vacíos omitidos: #{skipped_empty} | corregidos: #{fixed}"
  end
end
