# Copyright © Mapotempo, 2016
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
class V01::Entities::Visit < Grape::Entity
  def self.entity_name
    'V01_Visit'
  end

  expose(:id, documentation: { type: Integer })
  expose(:destination_id, documentation: { type: Integer })
  expose(:quantity, documentation: { type: Integer, desc: 'Deprecated, use quantities instead.' }) { |m|
    if m.quantities && m.destination.customer.deliverable_units.size == 1
      quantities = m.quantities.values
      quantities[0] if quantities.size == 1
    end
  }
  expose(:quantity_default, documentation: { type: Integer, desc: 'Deprecated, use quantities instead.' }) { |m|
    if m.quantities && m.destination.customer.deliverable_units.size == 1
      m.destination.customer.deliverable_units[0].default_quantity
    end
  }
  expose(:quantities, using: V01::Entities::DeliverableUnitQuantity, documentation: { type: V01::Entities::DeliverableUnitQuantity, is_array: true, param_type: 'form' }) { |m|
    m.quantities ? m.quantities.to_a.collect{ |a| {deliverable_unit_id: a[0], quantity: a[1]} } : []
  }
  expose(:open, documentation: { types: [Integer, DateTime], desc: 'Deprecated, use open1 instead.' }) { |m| m.open1_time }
  expose(:close, documentation: { types: [Integer, DateTime], desc: 'Deprecated, use close2 instead.' }) { |m| m.close1_time }
  expose(:open1, documentation: { types: [Integer, DateTime] }) { |m| m.open1_time }
  expose(:close1, documentation: { types: [Integer, DateTime] }) { |m| m.close1_time }
  expose(:open2, documentation: { types: [Integer, DateTime] }) { |m| m.open2_time }
  expose(:close2, documentation: { types: [Integer, DateTime] }) { |m| m.close2_time }
  expose(:ref, documentation: { type: String })
  expose(:take_over, documentation: { types: [Integer, DateTime], desc: 'Visit duration.' }) { |m| m.take_over_time }
  expose(:take_over_default, documentation: { type: DateTime }) { |m| m.destination.customer && m.destination.customer.take_over_time }
  expose(:tag_ids, documentation: { type: Integer, is_array: true })
end
