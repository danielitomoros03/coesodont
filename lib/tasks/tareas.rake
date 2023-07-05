desc "Actualiza todas inscripciones segun el reglamento"
task :update_all_enrollment_status => :environment do
	begin
		p 'iniciando... '
		AcademicProcess.reorder(name: :asc).each do |ap|
			p "Periodo: #{ap.period_name}"
			ap.enroll_academic_processes.each do |eap| 
				if eap.finished?
					print eap.update(permanence_status: eap.get_regulation) ? '.' : 'x'

				else
					print "-#{eap.id}-"
				end
			end
			p "/"
    	end

	rescue StandardError => e
		p e
	end
	
end

