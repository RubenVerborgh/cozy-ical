time = require 'time'
moment = require 'moment-timezone'
timezones = require './timezones'


icalDateToUTC = (date, tzid) ->
    isUTC = date[date.length - 1] is 'Z'
    mdate = moment date, "YYYYMMDDTHHmm00"
    if isUTC
        tdate = new time.Date mdate, 'UTC'
    else
        tdate = new time.Date mdate, tzid
        tdate.setTimezone 'UTC'
    return tdate


module.exports = (Event) ->
    {VCalendar, VEvent} = require './index'

    # Event::toIcal = (timezone = "UTC") ->
    Event::toIcal = ->
        # Stay in event locale timezone for recurrent events.
        timezone = (if @rrule then @timezone else 'GMT')

        event = new VEvent(
            moment.tz(@start, timezone),
            moment.tz(@end, timezone),
            @description, @place, @id, @details, undefined # wholeday
            @rrule, @timezone)

        return event

    Event.fromIcal = (vevent, timezone = "UTC") ->
        
        event = new Event()
        timezone = 'UTC' unless timezones[timezone]

        event.description = vevent.fields["SUMMARY"] or
                            vevent.fields["DESCRIPTION"]
        event.details = vevent.fields["DESCRIPTION"] or
                            vevent.fields["SUMMARY"]

        event.place = vevent.fields["LOCATION"]
        event.rrule = vevent.fields["RRULE"]

        tzStart = vevent.fields["DTSTART-TZID"] or timezone
        tzStart = 'UTC' unless timezones[tzStart]
        startDate = icalDateToUTC vevent.fields["DTSTART"], tzStart

        tzEnd = vevent.fields["DTEND-TZID"] or timezone
        tzEnd = 'UTC' unless timezones[tzEnd]
        endDate = icalDateToUTC vevent.fields["DTEND"], tzEnd

        event.start = startDate.toString().slice 0, 24
        event.end = endDate.toString().slice 0, 24
        event

    Event.extractEvents = (component, timezone) ->
        events = []
        timezone = 'UTC' unless timezones[timezone]
        component.walk (component) ->
            if component.name is 'VEVENT'
                events.push Event.fromIcal component, timezone

        events
