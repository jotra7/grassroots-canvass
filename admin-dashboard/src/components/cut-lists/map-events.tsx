"use client";

import { useMapEvents } from "react-leaflet";

interface MapClickHandlerProps {
  isDrawing: boolean;
  onMapClick: (latlng: { lat: number; lng: number }) => void;
}

export function MapClickHandler({ isDrawing, onMapClick }: MapClickHandlerProps) {
  useMapEvents({
    click(e) {
      if (isDrawing) {
        onMapClick({ lat: e.latlng.lat, lng: e.latlng.lng });
      }
    },
  });
  return null;
}
