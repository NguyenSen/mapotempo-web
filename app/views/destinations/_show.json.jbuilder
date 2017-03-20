json.extract! destination, :id, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :phone_number, :comment, :geocoding_accuracy, :geocoding_level
json.ref destination.ref if @customer.enable_references
json.geocoding_level_point destination.point?
json.geocoding_level_house destination.house?
json.geocoding_level_street destination.street?
json.geocoding_level_intersection destination.intersection?
json.geocoding_level_city destination.city?
if destination.geocoding_level
  json.geocoding_level_title t('activerecord.attributes.destination.geocoding_level') + ' : ' + t('destinations.form.geocoding_level.' + destination.geocoding_level.to_s)
end
json.tag_ids do
  json.array! destination.tags.collect(&:id)
end
json.has_no_position !destination.position? ? t('destinations.index.no_position') : false
json.visits do
  json.array! destination.visits do |visit|
    json.extract! visit, :id
    json.ref visit.ref if @customer.enable_references
    json.take_over visit.take_over_time
    json.duration visit.default_take_over_time
    unless @customer.enable_orders
      if @customer.deliverable_units.size == 1
        json.quantity visit.quantities && visit.quantities[@customer.deliverable_units[0].id]
        json.quantity_default @customer.deliverable_units[0].default_quantity
      elsif visit.default_quantities.values.compact.size > 1
        json.multiple_quantities true
      end
      json.quantities do
        json.array! visit.default_quantities do |k, v|
          #now return {} if value is nil
          unless v.nil?
            json.deliverable_unit_id k
            json.quantity v
            json.unit_icon @customer.deliverable_units.find { |du| du.id == k }.try(:default_icon)
          end
        end
      end
    end
    json.open1 visit.open1_time
    json.close1 visit.close1_time
    json.open2 visit.open2_time
    json.close2 visit.close2_time
    json.tag_ids do
      json.array! visit.tags.collect(&:id)
    end
  end
end
