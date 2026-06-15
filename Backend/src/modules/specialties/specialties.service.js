import { listSpecialties as dbListSpecialties } from '../admin/specialties/specialties.store.js';

export async function listSpecialtiesService() {
  return dbListSpecialties({ includeInactive: false });
}