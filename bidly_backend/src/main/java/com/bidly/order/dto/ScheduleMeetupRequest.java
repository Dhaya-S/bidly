package com.bidly.order.dto;

import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public class ScheduleMeetupRequest {

    @NotBlank(message = "Meetup location is required")
    private String location;

    private Instant meetupTime;

    private String dateString; // e.g. "2026-06-22"

    private String timeString; // e.g. "10:00 AM"

    private String notes;

    private String clientActionId;

    public ScheduleMeetupRequest() {}

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public Instant getMeetupTime() { return meetupTime; }
    public void setMeetupTime(Instant meetupTime) { this.meetupTime = meetupTime; }

    public String getDateString() { return dateString; }
    public void setDateString(String dateString) { this.dateString = dateString; }

    public String getTimeString() { return timeString; }
    public void setTimeString(String timeString) { this.timeString = timeString; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getClientActionId() { return clientActionId; }
    public void setClientActionId(String clientActionId) { this.clientActionId = clientActionId; }
}
