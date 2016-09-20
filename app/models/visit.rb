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
class QuantitiesValidator < ActiveModel::Validator
  def validate(record)
    !record.quantities || record.quantities.values.each{ |q| !q || Float(q) }
  rescue
    record.errors[:quantities] << I18n.t('activerecord.errors.models.visit.attributes.quantities.not_float')
  end
end

class Visit < ActiveRecord::Base
  belongs_to :destination
  has_many :stop_visits, inverse_of: :visit, dependent: :delete_all
  has_many :orders, inverse_of: :visit, dependent: :delete_all
  has_and_belongs_to_many :tags, after_add: :update_tags_track, after_remove: :update_tags_track
  delegate :lat, :lng, :name, :street, :postalcode, :city, :country, :detail, :comment, :phone_number, to: :destination
  serialize :quantities, DeliverableUnitQuantity

  nilify_blanks
  validates :destination, presence: true
  validates_time :open1, if: :open1
  validates_time :close1, presence: false, on_or_after: :open1, if: :close1
  validates :close1, presence: true, if: :open2
  validates_time :open2, on_or_after: :close1, if: :open2
  validates_time :close2, presence: false, on_or_after: :open2, if: :close2
  validates_with QuantitiesValidator, fields: [:quantities]

  before_save :update_tags, :create_orders
  before_update :update_out_of_date

  include RefSanitizer

  include LocalizedAttr

  attr_localized :quantities

  amoeba do
    exclude_association :stop_visits
    exclude_association :orders

    customize(lambda { |_original, copy|
      def copy.update_tags; end

      def copy.create_orders; end

      def copy.update_out_of_date; end
    })
  end

  def destroy
    # Too late to do this in before_destroy callback, children already destroyed
    Route.transaction do
      stop_visits.each{ |stop|
        stop.route.remove_stop(stop)
        stop.route.save
      }
    end
    super
  end

  def changed?
    @tags_updated || super
  end

  def out_of_date
    Route.transaction do
      stop_visits.each{ |stop|
        stop.route.out_of_date = true
        stop.route.optimized_at = stop.route.last_sent_to = stop.route.last_sent_at = nil
        stop.route.save
      }
    end
  end

  def default_quantities
    @default_quantities ||= Hash[destination.customer.deliverable_units.collect{ |du|
      [du.id, quantities && quantities[du.id] ? quantities[du.id] : du.default_quantity]
    }]
    @default_quantities
  end

  def default_quantities?
    default_quantities && default_quantities.values.any?{ |q| q && q > 0 }
  end

  def quantities?
    quantities && quantities.values.any?{ |q| q }
  end

  def quantities_changed?
    quantities ? quantities.each_with_index.any?{ |q, i|
      quantities_was && q != quantities_was[i]
    } : !!quantities_was
  end

  private

  def update_out_of_date
    if open1_changed? || close1_changed? || open2_changed? || close2_changed? || quantities_changed? || take_over_changed?
      out_of_date
    end
  end

  def update_tags_track(_tag)
    @tags_updated = true
  end

  def update_tags
    if destination.customer && (@tags_updated || new_record?)
      @tags_updated = false

      # Don't use local collection here, not set when save new record
      destination.customer.plannings.each{ |planning|
        if planning.visits.include?(self)
          if (planning.tags.to_a & (tags.to_a | destination.tags.to_a)) != planning.tags.to_a
            planning.visit_remove(self)
          end
        elsif (planning.tags.to_a & (tags.to_a | destination.tags.to_a)) == planning.tags.to_a
          planning.visit_add(self)
        end
      }
    end

    true
  end

  def create_orders
    if destination.customer && new_record?
      destination.customer.order_arrays.each{ |order_array|
        order_array.add_visit(self)
      }
    end
  end
end
