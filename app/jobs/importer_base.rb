# Copyright © Mapotempo, 2013-2015
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'csv'

class ImporterBase

  def initialize(customer)
    @customer = customer
  end

  def import(data, replace, name, synchronous, ignore_error)
    errors = []
    Store.transaction do
      before_import(replace, name, synchronous)

      data.each_with_index{ |row, line|
        row = yield(row)

        if row.size == 0
          next # Skip empty line
        end

        begin
          dest = import_row(replace, name, row, line)
          if !synchronous || Mapotempo::Application.config.delayed_job_use
            dest.delay_geocode
          end
        rescue => e
          if ignore_error
            errors << e if !errors.include?(e)
          else
            raise
          end
        end
      }
      after_import(replace, name, synchronous)
    end
    finalize_import(replace, name, synchronous)
    if errors.size > 0
      raise errors.join(', ')
    end
    true
  end
end
